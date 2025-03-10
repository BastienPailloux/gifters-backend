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
    context "when authenticated" do
      context "when the user is an admin of the group" do
        let!(:invitation) { create(:invitation, group: group, created_by: user) }

        before { get "/api/v1/groups/#{group.id}/invitations", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns all invitations for the group" do
          expect(JSON.parse(response.body).size).to eq(1)
        end

        it "returns invitations with correct attributes" do
          invitation_response = JSON.parse(response.body).first
          expect(invitation_response).to include('id', 'token', 'group_id', 'created_by_id', 'role', 'used')
          expect(invitation_response['created_by']).to include('id', 'name', 'email')
        end
      end

      context "when the user is not an admin of the group" do
        before do
          # Changer le rôle de l'utilisateur à membre
          membership = group.memberships.find_by(user: user)
          membership.update(role: 'member')

          get "/api/v1/groups/#{group.id}/invitations", headers: headers
        end

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to manage invitations')
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

    context "when not authenticated" do
      before { get "/api/v1/groups/#{group.id}/invitations" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
