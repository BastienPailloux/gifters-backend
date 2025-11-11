require 'rails_helper'

RSpec.describe "Api::V1::Invitations", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  # Création d'un groupe et ajout de l'utilisateur comme admin
  let(:group) { create(:group) }
  let(:another_user) { create(:user) }

  before do
    group.add_user(user, 'admin')
    group.add_user(another_user, 'member')
  end

  describe "GET /api/v1/groups/:group_id/invitations" do
    context "when user is admin of the group" do
      before do
        create_list(:invitation, 3, group: group, created_by: user)
        get "/api/v1/groups/#{group.id}/invitations", headers: headers
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all invitations for the group" do
        json_response = JSON.parse(response.body)
        invitations = json_response['invitations']
        expect(invitations.size).to eq(3)
      end
    end

    context "when user is not admin of the group" do
      let(:user) { another_user }  # Utiliser another_user qui est déjà un membre standard

      before do
        get "/api/v1/groups/#{group.id}/invitations", headers: headers
      end

      it "returns http forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the group does not exist" do
      before { get "/api/v1/groups/999/invitations", headers: headers }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end

      it "returns a not found message" do
        expect(JSON.parse(response.body)).to include('error' => 'Group not found')
      end
    end
  end

  describe "GET /api/v1/invitations/:token" do
    let(:invitation) { create(:invitation, group: group, created_by: user) }

    context "when the invitation exists" do
      before { get "/api/v1/invitations/#{invitation.token}", headers: headers }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns the invitation details" do
        invitation_response = JSON.parse(response.body)
        expect(invitation_response).to include('id', 'token', 'group_id', 'created_by_id', 'role')
      end
    end

    context "when the invitation does not exist" do
      before { get "/api/v1/invitations/invalid-token", headers: headers }

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        expect(JSON.parse(response.body)).to include('error' => 'Invitation not found')
      end
    end
  end

  describe "POST /api/v1/groups/:group_id/invitations" do
    let(:valid_attributes) { { invitation: { role: 'member' } } }
    let(:invalid_attributes) { { invitation: { role: 'invalid_role' } } }

    context "when user is admin of the group" do
      context "with valid parameters" do
        let(:valid_params) { { invitation: { role: 'member' }, email: 'test@example.com', message: 'Join our group!' } }

        it "creates a new invitation" do
          expect {
            post "/api/v1/groups/#{group.id}/invitations", params: valid_params, headers: headers
          }.to change(Invitation, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it "returns the created invitation" do
          post "/api/v1/groups/#{group.id}/invitations", params: valid_params, headers: headers
          expect(JSON.parse(response.body)).to include('invitation', 'invitation_url', 'token')
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) { { invitation: { role: 'invalid_role' } } }

        it "does not create a new invitation" do
          expect {
            post "/api/v1/groups/#{group.id}/invitations", params: invalid_params, headers: headers
          }.not_to change(Invitation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not admin of the group" do
      # Utiliser another_user qui est déjà un membre standard
      let(:user) { another_user }

      before do
        post "/api/v1/groups/#{group.id}/invitations", params: valid_attributes, headers: headers
      end

      it "returns http forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/groups/#{group.id}/invitations", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/invitations/:id" do
    let!(:invitation) { create(:invitation, group: group, created_by: user) }

    context "when user is admin of the group" do
      # L'utilisateur est déjà admin du groupe dans le before global

      it "deletes the invitation" do
        delete "/api/v1/invitations/#{invitation.token}", headers: headers
        expect(response).to have_http_status(:no_content)
        expect { invitation.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is the creator of the invitation" do
      it "deletes the invitation" do
        delete "/api/v1/invitations/#{invitation.token}", headers: headers
        expect(response).to have_http_status(:no_content)
        expect { invitation.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is neither admin nor creator" do
      let(:other_user) { create(:user) }
      let(:other_user_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(other_user)}" } }

      before do
        create(:membership, user: other_user, group: group, role: 'member')
      end

      it "returns http forbidden" do
        delete "/api/v1/invitations/#{invitation.token}", headers: other_user_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/invitations/#{invitation.token}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/invitations/accept" do
    let(:invitation) { create(:invitation, group: group, created_by: user) }
    let(:new_user) { create(:user) }
    let(:new_user_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(new_user)}" } }

    it "sends an email to the admin when a user accepts an invitation" do
      expect {
        post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      # Vérifier que l'email a été envoyé au bon destinataire
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(user.email)
      # Vérifier que le sujet contient la bonne information
      expect(email.subject).to include("has joined your group on Gifters")
    end

    context "when the invitation is valid" do
      before { post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "creates a membership for the user" do
        expect(Membership.find_by(user: new_user, group: group)).to be_present
      end

      it "returns success response" do
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['results'].size).to eq(1)
        expect(json_response['results'][0]['user_id']).to eq(new_user.id)
      end
    end

    context "when accepting invitation for a managed child" do
      let(:parent_user) { create(:user) }
      let(:child_user) { create(:user, parent: parent_user, account_type: 'managed') }
      let(:parent_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(parent_user)}" } }

      it "allows parent to accept invitation for their child" do
        expect {
          post "/api/v1/invitations/accept",
               params: { token: invitation.token, user_ids: [child_user.id] },
               headers: parent_headers
        }.to change { group.users.reload.count }.by(1)

        expect(response).to have_http_status(:success)
        expect(Membership.find_by(user: child_user, group: group)).to be_present
      end

      it "sends an email notification when child joins" do
        expect {
          post "/api/v1/invitations/accept",
               params: { token: invitation.token, user_ids: [child_user.id] },
               headers: parent_headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "returns success response for child" do
        post "/api/v1/invitations/accept",
             params: { token: invitation.token, user_ids: [child_user.id] },
             headers: parent_headers

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['results'].size).to eq(1)
        expect(json_response['results'][0]['user_id']).to eq(child_user.id)
        expect(json_response['results'][0]['user_name']).to eq(child_user.name)
      end

      it "prevents parent from adding a user that is not their child" do
        other_user = create(:user)

        post "/api/v1/invitations/accept",
             params: { token: invitation.token, user_ids: [other_user.id] },
             headers: parent_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Membership.find_by(user: other_user, group: group)).to be_nil

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors'][0]['error']).to eq('Not authorized to add this user')
      end
    end

    context "when accepting invitation for multiple users" do
      let(:parent_user) { create(:user) }
      let(:child1) { create(:user, parent: parent_user, account_type: 'managed') }
      let(:child2) { create(:user, parent: parent_user, account_type: 'managed') }
      let(:parent_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(parent_user)}" } }

      it "allows parent to accept invitation for themselves and children" do
        user_ids = [parent_user.id, child1.id, child2.id]

        expect {
          post "/api/v1/invitations/accept",
               params: { token: invitation.token, user_ids: user_ids },
               headers: parent_headers
        }.to change { group.users.reload.count }.by(3)

        expect(response).to have_http_status(:success)
        expect(Membership.find_by(user: parent_user, group: group)).to be_present
        expect(Membership.find_by(user: child1, group: group)).to be_present
        expect(Membership.find_by(user: child2, group: group)).to be_present
      end

      it "sends email notifications for each user" do
        user_ids = [parent_user.id, child1.id, child2.id]

        expect {
          post "/api/v1/invitations/accept",
               params: { token: invitation.token, user_ids: user_ids },
               headers: parent_headers
        }.to change { ActionMailer::Base.deliveries.count }.by(3)
      end

      it "returns success response for all users" do
        user_ids = [parent_user.id, child1.id, child2.id]

        post "/api/v1/invitations/accept",
             params: { token: invitation.token, user_ids: user_ids },
             headers: parent_headers

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['results'].size).to eq(3)
        expect(json_response['message']).to eq('3 user(s) successfully joined the group')
      end

      it "handles partial success when one user is already a member" do
        # Faire rejoindre child1 en premier
        group.add_user(child1, 'member')

        user_ids = [parent_user.id, child1.id, child2.id]

        post "/api/v1/invitations/accept",
             params: { token: invitation.token, user_ids: user_ids },
             headers: parent_headers

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['results'].size).to eq(2) # parent et child2
        expect(json_response['errors'].size).to eq(1) # child1 déjà membre
        expect(json_response['errors'][0]['user_id']).to eq(child1.id)
        expect(json_response['errors'][0]['error']).to eq('Already a member of this group')
      end
    end

    context "when the user is already a member of the group" do
      before do
        create(:membership, user: new_user, group: group)
        post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers
      end

      it "returns http unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors'][0]['error']).to eq('Already a member of this group')
      end
    end

    context "when the invitation does not exist" do
      before { post "/api/v1/invitations/accept", params: { token: 'invalid-token' }, headers: new_user_headers }

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        expect(JSON.parse(response.body)).to include('error' => 'Invitation not found')
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/invitations/accept", params: { token: invitation.token } }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
