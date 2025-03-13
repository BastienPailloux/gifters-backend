require 'rails_helper'

RSpec.describe "Api::V1::Groups", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  describe "GET /api/v1/groups" do
    context "when authenticated" do
      before do
        # Créer des groupes et ajouter l'utilisateur à certains d'entre eux
        @group1 = create(:group)
        @group2 = create(:group)
        @group3 = create(:group)

        # Ajouter l'utilisateur à deux groupes
        @group1.add_user(user)
        @group2.add_user(user)

        get "/api/v1/groups", headers: headers
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns only groups the user is a member of" do
        groups = JSON.parse(response.body)
        expect(groups.size).to eq(2)
        group_ids = groups.map { |g| g['id'] }
        expect(group_ids).to include(@group1.id, @group2.id)
        expect(group_ids).not_to include(@group3.id)
      end

      it "returns groups with correct attributes" do
        groups = JSON.parse(response.body)
        expect(groups.first).to include('id', 'name', 'description')
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/groups" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "GET /api/v1/groups/:id" do
    let(:group) { create(:group) }
    let(:group_id) { group.id }

    context "when authenticated" do
      context "when the user is a member of the group" do
        before do
          group.add_user(user)
          get "/api/v1/groups/#{group_id}", headers: headers
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns the group" do
          expect(JSON.parse(response.body)['id']).to eq(group_id)
        end

        it "returns group with correct attributes" do
          group_response = JSON.parse(response.body)
          expect(group_response).to include('id', 'name', 'description')
          expect(group_response).to include('members')
        end

        it "includes members in the response" do
          group_response = JSON.parse(response.body)
          expect(group_response['members']).to be_an(Array)
          expect(group_response['members'].first).to include('id', 'name', 'email', 'role')
        end
      end

      context "when the user is not a member of the group" do
        before { get "/api/v1/groups/#{group_id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end

      context "when the group does not exist" do
        let(:group_id) { 999 }
        before { get "/api/v1/groups/#{group_id}", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Group not found')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/groups/#{group_id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/groups" do
    let(:valid_attributes) { { group: { name: "New Group", description: "A new test group" } } }
    let(:invalid_attributes) { { group: { name: "", description: "Invalid group" } } }

    context "when authenticated" do
      context "when the request is valid" do
        before { post "/api/v1/groups", params: valid_attributes, headers: headers }

        it "returns status code 201" do
          expect(response).to have_http_status(201)
        end

        it "creates a new group" do
          expect(JSON.parse(response.body)['name']).to eq("New Group")
        end

        it "adds the current user as an admin of the group" do
          group_id = JSON.parse(response.body)['id']
          group = Group.find(group_id)

          expect(group.users).to include(user)
          expect(group.admin_users).to include(user)
        end
      end

      context "when the request is invalid" do
        before { post "/api/v1/groups", params: invalid_attributes, headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns a validation failure message" do
          expect(JSON.parse(response.body)).to include('errors')
        end
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/groups", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/groups/:id" do
    let(:group) { create(:group) }
    let(:group_id) { group.id }
    let(:valid_attributes) { { group: { name: "Updated Group", description: "Updated description" } } }

    context "when authenticated" do
      context "when the user is an admin of the group" do
        before do
          group.add_user(user, 'admin')
          put "/api/v1/groups/#{group_id}", params: valid_attributes, headers: headers
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "updates the group" do
          expect(JSON.parse(response.body)['name']).to eq("Updated Group")
          expect(JSON.parse(response.body)['description']).to eq("Updated description")
        end
      end

      context "when the user is a member but not an admin of the group" do
        before do
          group.add_user(user, 'member')
          put "/api/v1/groups/#{group_id}", params: valid_attributes, headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to update this group')
        end
      end

      context "when the user is not a member of the group" do
        before { put "/api/v1/groups/#{group_id}", params: valid_attributes, headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/groups/#{group_id}", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/groups/:id" do
    let(:group) { create(:group) }
    let(:group_id) { group.id }

    context "when authenticated" do
      context "when the user is an admin of the group" do
        before do
          group.add_user(user, 'admin')
          delete "/api/v1/groups/#{group_id}", headers: headers
        end

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the group" do
          expect(Group.find_by(id: group_id)).to be_nil
        end
      end

      context "when the user is a member but not an admin of the group" do
        before do
          group.add_user(user, 'member')
          delete "/api/v1/groups/#{group_id}", headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to delete this group')
        end
      end

      context "when the user is not a member of the group" do
        before { delete "/api/v1/groups/#{group_id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/groups/#{group_id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/groups/:id/join" do
    let(:group) { create(:group) }
    let(:group_id) { group.id }
    let(:valid_attributes) { { invite_code: group.invite_code } }
    let(:invalid_attributes) { { invite_code: "WRONG123" } }

    context "when authenticated" do
      context "when the invite code is valid" do
        before { post "/api/v1/groups/#{group_id}/join", params: valid_attributes, headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "adds the user to the group" do
          expect(group.users.reload).to include(user)
        end

        it "returns a success message" do
          expect(JSON.parse(response.body)).to include('message' => 'Successfully joined the group')
        end
      end

      context "when the user is already a member of the group" do
        before do
          group.add_user(user)
          post "/api/v1/groups/#{group_id}/join", params: valid_attributes, headers: headers
        end

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are already a member of this group')
        end
      end

      context "when the invite code is invalid" do
        before { post "/api/v1/groups/#{group_id}/join", params: invalid_attributes, headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'Invalid invite code')
        end
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/groups/#{group_id}/join", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/groups/:id/leave" do
    let(:group) { create(:group) }
    let(:group_id) { group.id }

    context "when authenticated" do
      context "when the user is a member of the group" do
        before do
          group.add_user(user)
          delete "/api/v1/groups/#{group_id}/leave", headers: headers
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "removes the user from the group" do
          expect(group.users.reload).not_to include(user)
        end

        it "returns a success message" do
          expect(JSON.parse(response.body)).to include('message' => 'Successfully left the group')
        end
      end

      context "when the user is the last admin of the group" do
        before do
          group.add_user(user, 'admin')
          delete "/api/v1/groups/#{group_id}/leave", headers: headers
        end

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'You cannot leave the group as you are the last admin')
        end
      end

      context "when the user is not a member of the group" do
        before { delete "/api/v1/groups/#{group_id}/leave", headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/groups/#{group_id}/leave" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
