require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  describe "GET /api/v1/users" do
    context "when authenticated" do
      before do
        # Créer quelques utilisateurs pour les tests
        create_list(:user, 3)
        get "/api/v1/users", headers: headers
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns all users" do
        expect(JSON.parse(response.body)["users"].size).to eq(4) # 3 créés + 1 utilisateur authentifié
      end

      it "returns users with correct attributes" do
        users = JSON.parse(response.body)["users"]
        expect(users.first).to include('id', 'name', 'email')
        expect(users.first).not_to include('password_digest', 'created_at', 'updated_at')
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/users" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    let(:user_id) { user.id }

    context "when authenticated" do
      context "when the user exists" do
        before { get "/api/v1/users/#{user_id}", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns the user" do
          expect(JSON.parse(response.body)["user"]['id']).to eq(user_id)
        end

        it "returns user with correct attributes" do
          user_response = JSON.parse(response.body)["user"]
          expect(user_response).to include('id', 'name', 'email')
          expect(user_response).not_to include('password_digest', 'created_at', 'updated_at')
        end
      end

      context "when the user does not exist" do
        let(:user_id) { 999 }
        before { get "/api/v1/users/#{user_id}", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/users/#{user_id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  # Tests pour l'inscription des utilisateurs (maintenant gérée par Devise)
  describe "POST /api/v1/signup" do
    let(:valid_attributes) { { user: { name: "New User", email: "new@example.com", password: "password", password_confirmation: "password" } } }
    let(:invalid_attributes) { { user: { name: "", email: "invalid", password: "pass" } } }

    context "when the request is valid" do
      before { post "/api/v1/signup", params: valid_attributes }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "creates a new user" do
        expect(JSON.parse(response.body)['data']['user']['name']).to eq("New User")
      end

      it "returns a JWT token" do
        expect(JSON.parse(response.body)['data']).to include('token')
      end
    end

    context "when the request is invalid" do
      before { post "/api/v1/signup", params: invalid_attributes }

      it "returns status code 422" do
        expect(response).to have_http_status(422)
      end

      it "returns a validation failure message" do
        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end

  describe "PUT /api/v1/users/:id" do
    let(:valid_attributes) { { user: { name: "Updated Name" } } }
    let(:user_id) { user.id }

    context "when authenticated" do
      context "when updating own profile" do
        before { put "/api/v1/users/#{user_id}", params: valid_attributes, headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "updates the user" do
          expect(JSON.parse(response.body)["user"]['name']).to eq("Updated Name")
        end
      end

      context "when trying to update another user's profile" do
        let(:another_user) { create(:user) }
        let(:user_id) { another_user.id }

        before { put "/api/v1/users/#{user_id}", params: valid_attributes, headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'Forbidden')
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/users/#{user_id}", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/users/:id" do
    let(:user_id) { user.id }

    context "when authenticated" do
      context "when deleting own profile" do
        before { delete "/api/v1/users/#{user_id}", headers: headers }

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the user" do
          expect(User.find_by(id: user_id)).to be_nil
        end
      end

      context "when trying to delete another user's profile" do
        let(:another_user) { create(:user) }
        let(:user_id) { another_user.id }

        before { delete "/api/v1/users/#{user_id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'Forbidden')
        end
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/users/#{user_id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
