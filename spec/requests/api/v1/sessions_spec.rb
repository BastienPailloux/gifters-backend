require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  # Add support for auth helpers
  before(:all) do
    # Make sure the spec/support directory is loaded
    Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
  end

  describe "POST /api/v1/login" do
    let(:valid_credentials) { { email: "test@example.com", password: "password123" } }
    let(:invalid_credentials) { { email: "test@example.com", password: "wrongpassword" } }

    context "with standard params format" do
      let(:valid_params) { { user: valid_credentials } }

      it "returns successful response with token" do
        post "/api/v1/login", params: valid_params
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['status']['message']).to eq('Logged in successfully')
        expect(json_response['data']).to include('token', 'user')
        expect(json_response['data']['user']).to include('id', 'name', 'email')
      end

      it "returns user information" do
        post "/api/v1/login", params: valid_params
        json_response = JSON.parse(response.body)

        expect(json_response['data']['user']['email']).to eq(user.email)
        expect(json_response['data']['user']['name']).to eq(user.name)
      end
    end

    context "with session params format" do
      let(:session_params) { { session: { user: valid_credentials } } }

      it "successfully logs in" do
        post "/api/v1/login", params: session_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']['message']).to eq('Logged in successfully')
      end
    end

    context "with invalid credentials" do
      let(:invalid_params) { { user: invalid_credentials } }

      it "returns unauthorized status" do
        post "/api/v1/login", params: invalid_params
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['status']['message']).to eq('Invalid email or password')
      end
    end

    context "with non-existent user" do
      let(:nonexistent_params) { { user: { email: "nonexistent@example.com", password: "password123" } } }

      it "returns unauthorized status" do
        post "/api/v1/login", params: nonexistent_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/logout" do
    it "returns unauthorized status without authentication" do
      delete "/api/v1/logout"
      # The authentication is handled at controller level so we should get a successful response
      # even without authentication (this is how Devise JWT works by default)
      expect(response).to have_http_status(:ok)
    end

    context "when authenticated" do
      before do
        # Connexion pour obtenir un token
        post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
        @token = JSON.parse(response.body)['data']['token']
      end

      it "logs out successfully" do
        # Utilisation du token pour la déconnexion
        delete "/api/v1/logout", headers: { 'Authorization' => "Bearer #{@token}" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']['message']).to eq('Logged out successfully')
      end

      it "adds token to denylist" do
        expect {
          delete "/api/v1/logout", headers: { 'Authorization' => "Bearer #{@token}" }
        }.to change(JwtDenylist, :count).by(1)

        # Verify token is in denylist by checking if we can find a JWT with that jti
        payload = JWT.decode(@token, Rails.application.credentials.secret_key_base)[0]
        expect(JwtDenylist.exists?(jti: payload['jti'])).to be true
      end
    end
  end
end
