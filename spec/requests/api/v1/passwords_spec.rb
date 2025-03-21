require 'rails_helper'

RSpec.describe "Api::V1::Passwords", type: :request do
  # Configurer uniquement le mock pour ENV
  before do
    # Mock ENV variables
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('http://localhost:5173')
  end

  before(:each) do
    # Configuration globale pour ActionMailer en mode test
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /api/v1/password" do
    let(:user) { create(:user, email: "test@example.com") }

    context "with valid email" do
      let(:valid_params) { { user: { email: user.email } } }

      it "sends reset password instructions" do
        expect {
          post "/api/v1/password", params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "returns success response" do
        post "/api/v1/password", params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('status' => hash_including('message' => 'Reset password instructions sent successfully'))
      end

      it "updates user locale if provided" do
        locale_params = { user: { email: user.email, locale: "fr" } }
        expect {
          post "/api/v1/password", params: locale_params
        }.to change { user.reload.locale }.to("fr")
      end
    end

    context "with invalid email" do
      let(:invalid_params) { { user: { email: "nonexistent@example.com" } } }

      it "returns unprocessable entity status" do
        post "/api/v1/password", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end

  describe "PUT /api/v1/password" do
    let(:user) { create(:user) }
    let(:reset_token) { user.send_reset_password_instructions }

    context "with valid token and password" do
      let(:valid_params) { {
        user: {
          reset_password_token: reset_token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      } }

      it "resets the password" do
        put "/api/v1/password", params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('status' => hash_including('message' => 'Password updated successfully'))
      end

      it "allows user to sign in with new password" do
        put "/api/v1/password", params: valid_params

        # Tester la connexion avec le nouveau mot de passe
        auth_params = { user: { email: user.email, password: "newpassword123" } }
        post "/api/v1/login", params: auth_params
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid token" do
      let(:invalid_params) { {
        user: {
          reset_password_token: "invalid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      } }

      it "returns error response" do
        put "/api/v1/password", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end

    context "with password confirmation mismatch" do
      let(:mismatch_params) { {
        user: {
          reset_password_token: reset_token,
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }
      } }

      it "returns error response" do
        put "/api/v1/password", params: mismatch_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end
end
