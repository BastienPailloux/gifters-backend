require 'rails_helper'

RSpec.describe "Api::V1::Memberships", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  # Création d'un groupe et ajout de l'utilisateur comme admin
  let(:group) { create(:group) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }

  before do
    group.add_user(user, 'admin')
    group.add_user(another_user, 'member')
  end

  # Création de memberships pour les tests
  let(:user_membership) { Membership.find_by(user: user, group: group) }
  let(:another_user_membership) { Membership.find_by(user: another_user, group: group) }

  describe "GET /api/v1/groups/:group_id/memberships" do
    context "when authenticated" do
      context "when the user is a member of the group" do
        before { get "/api/v1/groups/#{group.id}/memberships", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns all memberships for the group" do
          memberships = JSON.parse(response.body)
          expect(memberships.size).to eq(2)
          expect(memberships.map { |m| m['user_id'] }).to include(user.id, another_user.id)
        end

        it "returns memberships with correct attributes" do
          memberships = JSON.parse(response.body)
          expect(memberships.first).to include('id', 'user_id', 'group_id', 'role')
          expect(memberships.first).to include('user_name', 'user_email')
        end
      end

      context "when the user is not a member of the group" do
        let(:other_group) { create(:group) }

        before { get "/api/v1/groups/#{other_group.id}/memberships", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end

      context "when the group does not exist" do
        before { get "/api/v1/groups/999/memberships", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Group not found')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/groups/#{group.id}/memberships" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "GET /api/v1/groups/:group_id/memberships/:id" do
    context "when authenticated" do
      context "when the user is a member of the group" do
        before { get "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns the membership" do
          expect(JSON.parse(response.body)['id']).to eq(another_user_membership.id)
        end

        it "returns membership with correct attributes" do
          membership = JSON.parse(response.body)
          expect(membership).to include('id', 'user_id', 'group_id', 'role')
          expect(membership).to include('user_name', 'user_email')
        end
      end

      context "when the user is not a member of the group" do
        let(:other_group) { create(:group) }
        let(:other_membership) { other_group.add_user(third_user) }

        before { get "/api/v1/groups/#{other_group.id}/memberships/#{other_membership.id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end

      context "when the membership does not exist" do
        before { get "/api/v1/groups/#{group.id}/memberships/999", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Membership not found')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/groups/:group_id/memberships" do
    let(:valid_attributes) { { membership: { user_id: third_user.id, role: 'member' } } }
    let(:invalid_attributes) { { membership: { user_id: nil, role: 'invalid_role' } } }

    context "when authenticated" do
      context "when the user is an admin of the group" do
        context "when the request is valid" do
          before { post "/api/v1/groups/#{group.id}/memberships", params: valid_attributes, headers: headers }

          it "returns status code 201" do
            expect(response).to have_http_status(201)
          end

          it "creates a new membership" do
            expect(JSON.parse(response.body)['user_id']).to eq(third_user.id)
            expect(JSON.parse(response.body)['role']).to eq('member')
          end

          it "adds the user to the group" do
            expect(group.users.reload).to include(third_user)
          end
        end

        context "when the request is invalid" do
          before { post "/api/v1/groups/#{group.id}/memberships", params: invalid_attributes, headers: headers }

          it "returns status code 422" do
            expect(response).to have_http_status(422)
          end

          it "returns a validation failure message" do
            expect(JSON.parse(response.body)).to include('errors')
          end
        end

        context "when the user is already a member of the group" do
          before { post "/api/v1/groups/#{group.id}/memberships", params: { membership: { user_id: another_user.id, role: 'member' } }, headers: headers }

          it "returns status code 422" do
            expect(response).to have_http_status(422)
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)['errors']).to include(/User has already been taken/)
          end
        end
      end

      context "when the user is not an admin of the group" do
        before do
          # Changer le rôle de l'utilisateur à membre
          user_membership.update(role: 'member')
          post "/api/v1/groups/#{group.id}/memberships", params: valid_attributes, headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to add members to this group')
        end
      end

      context "when the user is not a member of the group" do
        let(:other_group) { create(:group) }

        before { post "/api/v1/groups/#{other_group.id}/memberships", params: valid_attributes, headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not a member of this group')
        end
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/groups/#{group.id}/memberships", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/groups/:group_id/memberships/:id" do
    let(:valid_attributes) { { membership: { role: 'admin' } } }

    context "when authenticated" do
      context "when the user is an admin of the group" do
        context "when updating another user's membership" do
          before { put "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", params: valid_attributes, headers: headers }

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end

          it "updates the membership" do
            expect(JSON.parse(response.body)['role']).to eq('admin')
          end
        end

        context "when updating own membership" do
          before { put "/api/v1/groups/#{group.id}/memberships/#{user_membership.id}", params: { membership: { role: 'member' } }, headers: headers }

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end

          it "updates the membership" do
            expect(JSON.parse(response.body)['role']).to eq('member')
          end
        end

        context "when the membership is the last admin" do
          before { put "/api/v1/groups/#{group.id}/memberships/#{user_membership.id}", params: { membership: { role: 'member' } }, headers: headers }

          it "returns status code 422" do
            expect(response).to have_http_status(422)
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)).to include('errors' => ['Cannot change role: group must have at least one admin'])
          end
        end
      end

      context "when the user is not an admin of the group" do
        before do
          # Ajouter un autre admin
          group.add_user(third_user, 'admin')
          # Changer le rôle de l'utilisateur à membre
          user_membership.update(role: 'member')
          put "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", params: valid_attributes, headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to update memberships in this group')
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/groups/:group_id/memberships/:id" do
    context "when authenticated" do
      context "when the user is an admin of the group" do
        context "when deleting another user's membership" do
          before { delete "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", headers: headers }

          it "returns status code 204" do
            expect(response).to have_http_status(204)
          end

          it "removes the user from the group" do
            expect(group.users.reload).not_to include(another_user)
          end
        end

        context "when deleting own membership" do
          before do
            # Ajouter un autre admin pour éviter d'être le dernier
            group.add_user(third_user, 'admin')
            delete "/api/v1/groups/#{group.id}/memberships/#{user_membership.id}", headers: headers
          end

          it "returns status code 204" do
            expect(response).to have_http_status(204)
          end

          it "removes the user from the group" do
            expect(group.users.reload).not_to include(user)
          end
        end

        context "when the membership is the last admin" do
          before { delete "/api/v1/groups/#{group.id}/memberships/#{user_membership.id}", headers: headers }

          it "returns status code 422" do
            expect(response).to have_http_status(422)
          end

          it "returns an error message" do
            expect(JSON.parse(response.body)).to include('errors' => ['Cannot delete membership: group must have at least one admin'])
          end
        end
      end

      context "when the user is not an admin of the group" do
        before do
          # Ajouter un autre admin
          group.add_user(third_user, 'admin')
          # Changer le rôle de l'utilisateur à membre
          user_membership.update(role: 'member')
          delete "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}", headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to remove members from this group')
        end
      end

      context "when deleting own membership as a non-admin" do
        before do
          # Ajouter un autre admin
          group.add_user(third_user, 'admin')
          # Changer le rôle de l'utilisateur à membre
          user_membership.update(role: 'member')
          delete "/api/v1/groups/#{group.id}/memberships/#{user_membership.id}", headers: headers
        end

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "removes the user from the group" do
          expect(group.users.reload).not_to include(user)
        end
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/groups/#{group.id}/memberships/#{another_user_membership.id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
