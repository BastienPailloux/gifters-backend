require 'rails_helper'

RSpec.describe 'Api::V1::Children', type: :request do
  let(:parent) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:child1) { create(:managed_user, parent: parent, name: 'Child 1') }
  let!(:child2) { create(:managed_user, parent: parent, name: 'Child 2') }
  let!(:other_child) { create(:managed_user, parent: other_user, name: 'Other Child') }

  describe 'GET /api/v1/children' do
    context 'when authenticated' do
      it 'returns all children of the authenticated user' do
        get '/api/v1/children', headers: auth_headers(parent)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['children'].size).to eq(2)
        child_names = json['children'].map { |c| c['name'] }
        expect(child_names).to include('Child 1', 'Child 2')
        expect(child_names).not_to include('Other Child')
      end

      it 'does not include sensitive fields' do
        get '/api/v1/children', headers: auth_headers(parent)

        json = JSON.parse(response.body)
        first_child = json['children'].first

        expect(first_child).not_to have_key('encrypted_password')
        expect(first_child).not_to have_key('reset_password_token')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/children'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/children/:id' do
    context 'when authenticated as parent' do
      it 'returns the child details' do
        get "/api/v1/children/#{child1.id}", headers: auth_headers(parent)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['child']['id']).to eq(child1.id)
        expect(json['child']['name']).to eq('Child 1')
      end
    end

    context 'when trying to access another user\'s child' do
      it 'returns forbidden' do
        get "/api/v1/children/#{other_child.id}", headers: auth_headers(parent)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to include('not the parent')
      end
    end

    context 'when child does not exist' do
      it 'returns not found' do
        get '/api/v1/children/99999', headers: auth_headers(parent)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/children' do
    context 'when authenticated' do
      let(:valid_attributes) do
        {
          user: {
            name: 'New Child',
            birthday: '2018-05-15',
            gender: 'male'
          }
        }
      end

      let(:invalid_attributes) do
        {
          user: {
            name: ''
          }
        }
      end

      it 'creates a new child account' do
        expect {
          post '/api/v1/children', params: valid_attributes, headers: auth_headers(parent)
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['child']['name']).to eq('New Child')
        expect(json['child']['account_type']).to eq('managed')
        expect(json['child']['parent_id']).to eq(parent.id)
        expect(json['message']).to include('successfully')
      end

      it 'creates child without email and password' do
        post '/api/v1/children', params: valid_attributes, headers: auth_headers(parent)

        json = JSON.parse(response.body)
        created_child = User.find(json['child']['id'])

        expect(created_child.email).to be_nil
        expect(created_child.encrypted_password).to be_blank
      end

      it 'returns errors for invalid attributes' do
        expect {
          post '/api/v1/children', params: invalid_attributes, headers: auth_headers(parent)
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/children', params: { user: { name: 'Test' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/children/:id' do
    context 'when authenticated as parent' do
      let(:update_attributes) do
        {
          user: {
            name: 'Updated Name',
            birthday: '2019-01-01'
          }
        }
      end

      it 'updates the child account' do
        put "/api/v1/children/#{child1.id}", params: update_attributes, headers: auth_headers(parent)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json['child']['name']).to eq('Updated Name')
        expect(json['child']['birthday']).to eq('2019-01-01')

        child1.reload
        expect(child1.name).to eq('Updated Name')
      end

      it 'returns errors for invalid updates' do
        put "/api/v1/children/#{child1.id}",
            params: { user: { name: '' } },
            headers: auth_headers(parent)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'when trying to update another user\'s child' do
      it 'returns forbidden' do
        put "/api/v1/children/#{other_child.id}",
            params: { user: { name: 'Hacked' } },
            headers: auth_headers(parent)

        expect(response).to have_http_status(:forbidden)

        other_child.reload
        expect(other_child.name).not_to eq('Hacked')
      end
    end
  end

  describe 'DELETE /api/v1/children/:id' do
    context 'when authenticated as parent' do
      it 'deletes the child account' do
        expect {
          delete "/api/v1/children/#{child1.id}", headers: auth_headers(parent)
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to include('deleted')

        expect(User.exists?(child1.id)).to be false
      end
    end

    context 'when trying to delete another user\'s child' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/children/#{other_child.id}", headers: auth_headers(parent)
        }.not_to change(User, :count)

        expect(response).to have_http_status(:forbidden)
        expect(User.exists?(other_child.id)).to be true
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/children/#{child1.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # Helper pour générer les headers d'authentification
  def auth_headers(user)
    token = JWT.encode(
      {
        user_id: user.id,
        email: user.email,
        name: user.name,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base
    )
    { 'Authorization' => "Bearer #{token}" }
  end
end
