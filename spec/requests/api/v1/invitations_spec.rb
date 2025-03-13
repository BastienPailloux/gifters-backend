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
        create(:membership, user: user, group: group, role: 'admin')
        create_list(:invitation, 3, group: group, created_by: user)
        get "/api/v1/groups/#{group.id}/invitations", headers: headers
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all invitations for the group" do
        invitations = JSON.parse(response.body)
        expect(invitations.size).to eq(3)
      end
    end

    context "when user is not admin of the group" do
      before do
        create(:membership, user: user, group: group, role: 'member')
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
      before do
        create(:membership, user: user, group: group, role: 'admin')
      end

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
      before do
        create(:membership, user: user, group: group, role: 'member')
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
      before do
        create(:membership, user: user, group: group, role: 'admin')
      end

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
      expect(email.subject).to eq("Un utilisateur a rejoint votre groupe sur Gifters")
    end

    context "when the invitation is valid" do
      before { post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "creates a membership for the user" do
        expect(Membership.find_by(user: new_user, group: group)).to be_present
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
        expect(JSON.parse(response.body)).to include('error' => 'You are already a member of this group')
      end
    end

    context "when the invitation does not exist" do
      before { post "/api/v1/invitations/accept", params: { token: 'invalid-token' }, headers: new_user_headers }

      it "returns http not found" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        expect(JSON.parse(response.body)).to include('error' => 'Invalid invitation token')
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
