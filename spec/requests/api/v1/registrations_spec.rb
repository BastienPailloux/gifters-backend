require 'rails_helper'

RSpec.describe "Api::V1::Registrations", type: :request do
  # Configurer un mock global pour ENV
  before do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with('BREVO_LIST_ID').and_return('6')
    allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('http://localhost:5173')
  end

  describe "POST /api/v1/signup" do
    let(:valid_attributes) do
      {
        name: "Test User",
        email: "test_signup@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    context "with standard params format" do
      let(:valid_params) { { user: valid_attributes } }

      it "creates a new user" do
        expect {
          post "/api/v1/signup", params: valid_params
        }.to change(User, :count).by(1)
      end

      it "returns a successful response with token" do
        post "/api/v1/signup", params: valid_params
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include('status' => hash_including('message' => 'Signed up successfully'))
        expect(json_response['data']).to include('token', 'user')
        expect(json_response['data']['user']).to include('id', 'name', 'email')
      end

      it "sets newsletter_subscription to false by default" do
        post "/api/v1/signup", params: valid_params
        expect(User.last.newsletter_subscription).to be_falsey
      end
    end

    context "with session params format" do
      let(:session_params) { { session: { user: valid_attributes } } }

      it "successfully creates a user" do
        expect {
          post "/api/v1/signup", params: session_params
        }.to change(User, :count).by(1)
      end
    end

    context "with registration params format" do
      let(:registration_params) { { registration: { user: valid_attributes } } }

      it "successfully creates a user" do
        expect {
          post "/api/v1/signup", params: registration_params
        }.to change(User, :count).by(1)
      end
    end

    context "with newsletter subscription" do
      let(:newsletter_params) {
        {
          user: valid_attributes.merge(newsletter_subscription: true)
        }
      }

      it "subscribes user to Brevo" do
        # Mocking the Brevo service call
        expect(BrevoService).to receive(:subscribe_contact).with("test_signup@example.com").and_return({ success: true })

        post "/api/v1/signup", params: newsletter_params
        expect(User.last.newsletter_subscription).to be_truthy
      end

      it "handles Brevo subscription failure gracefully" do
        allow(BrevoService).to receive(:subscribe_contact).and_return({ success: false, error: "API error" })

        expect {
          post "/api/v1/signup", params: newsletter_params
        }.to change(User, :count).by(1)

        # L'utilisateur doit être créé même si l'abonnement à Brevo échoue
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      context "when email is already taken" do
        before { create(:user, email: "test_signup@example.com") }

        it "returns validation error" do
          post "/api/v1/signup", params: { user: valid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include('errors')
        end
      end

      context "when password confirmation does not match" do
        let(:invalid_params) {
          {
            user: valid_attributes.merge(password_confirmation: "different")
          }
        }

        it "returns validation error" do
          post "/api/v1/signup", params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include(a_string_matching(/Password confirmation doesn't match/))
        end
      end

      context "when required fields are missing" do
        let(:incomplete_params) {
          {
            user: { email: "test_signup@example.com" }
          }
        }

        it "returns validation error" do
          post "/api/v1/signup", params: incomplete_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include(a_string_matching(/Password can't be blank/))
        end
      end
    end
  end
end
