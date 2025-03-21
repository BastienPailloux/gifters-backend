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
          expect(user_response).not_to include('encrypted_password', 'reset_password_token', 'reset_password_sent_at')
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

  describe "GET /api/v1/users/shared_users" do
    let(:other_user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:group) { create(:group) }

    before do
      # Créer un groupe et y ajouter l'utilisateur et other_user
      group.add_user(user, 'member')
      group.add_user(other_user, 'member')
      # another_user n'est pas dans le même groupe
    end

    context "when authenticated" do
      before { get "/api/v1/users/shared_users", headers: headers }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns ids of users in common groups" do
        user_ids = JSON.parse(response.body)["user_ids"]
        expect(user_ids).to include(other_user.id)
        expect(user_ids).not_to include(another_user.id)
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/users/shared_users" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PATCH /api/v1/users/:id/update_locale" do
    # Créer des users spécifiques pour ces tests pour éviter les conflits
    let(:locale_user) { create(:user, email: "locale-test@example.com", password: "password123") }
    let(:locale_other_user) { create(:user, email: "locale-other@example.com", password: "password123") }

    it "requires authentication" do
      patch "/api/v1/users/#{locale_user.id}/update_locale", params: { user: { locale: "fr" } }
      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)["error"]).to match(/Unauthorized/)
    end

    it "allows authenticated users to update their own locale" do
      # Login first
      post "/api/v1/login", params: { user: { email: locale_user.email, password: "password123" } }
      token = JSON.parse(response.body).dig("data", "token")

      # Then update locale
      patch "/api/v1/users/#{locale_user.id}/update_locale",
            params: { user: { locale: "fr" } },
            headers: { "Authorization" => "Bearer #{token}" }

      # Verify response
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)["data"]["locale"]).to eq("fr")
      expect(locale_user.reload.locale).to eq("fr")
    end

    it "prevents authenticated users from updating another user's locale" do
      # Login first
      post "/api/v1/login", params: { user: { email: locale_user.email, password: "password123" } }
      token = JSON.parse(response.body).dig("data", "token")

      # Try to update another user's locale
      patch "/api/v1/users/#{locale_other_user.id}/update_locale",
            params: { user: { locale: "fr" } },
            headers: { "Authorization" => "Bearer #{token}" }

      # Verify forbidden response
      expect(response).to have_http_status(403)
      expect(JSON.parse(response.body)["status"]["message"]).to match(/Not authorized/)
    end
  end
end
