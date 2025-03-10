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

  describe "GET /api/v1/invitations/:token" do
    let(:invitation) { create(:invitation, group: group, created_by: user) }

    context "when authenticated" do
      context "when the invitation is valid and unused" do
        before { get "/api/v1/invitations/#{invitation.token}", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns the invitation" do
          expect(JSON.parse(response.body)['id']).to eq(invitation.id)
        end

        it "returns invitation with correct attributes" do
          invitation_response = JSON.parse(response.body)
          expect(invitation_response).to include('id', 'token', 'group_id', 'created_by_id', 'role', 'used')
          expect(invitation_response['group']).to include('id', 'name')
          expect(invitation_response['created_by']).to include('id', 'name', 'email')
        end
      end

      context "when the invitation is used" do
        let(:used_invitation) { create(:invitation, :used, group: group, created_by: user) }

        before { get "/api/v1/invitations/#{used_invitation.token}", headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'This invitation has already been used')
        end
      end

      context "when the invitation does not exist" do
        before { get "/api/v1/invitations/invalid_token", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Invitation not found')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/invitations/#{invitation.token}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/groups/:group_id/invitations" do
    let(:valid_attributes) { { invitation: { role: 'member' } } }
    let(:invalid_attributes) { { invitation: { role: 'invalid_role' } } }

    context "when user is admin of the group" do
      it "creates a new invitation" do
        expect {
          post "/api/v1/groups/#{group.id}/invitations", params: valid_attributes, headers: headers
        }.to change(Invitation, :count).by(1)

        expect(response).to have_http_status(201)
        expect(JSON.parse(response.body)['invitation']['role']).to eq('member')
      end

      it "sends an email when an email address is provided" do
        recipient_email = "test@example.com"

        expect {
          post "/api/v1/groups/#{group.id}/invitations",
               params: { invitation: { role: 'member' }, email: recipient_email },
               headers: headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(201)

        # Vérifier que l'email a été envoyé au bon destinataire
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(recipient_email)
        expect(email.subject).to eq("Vous avez été invité à rejoindre un groupe sur Gifters")
      end

      it "returns a 422 status with errors for invalid attributes" do
        post "/api/v1/groups/#{group.id}/invitations", params: invalid_attributes, headers: headers

        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)).to have_key('errors')
      end

      it "includes the invitation URL and token in the response" do
        post "/api/v1/groups/#{group.id}/invitations", params: valid_attributes, headers: headers

        expect(JSON.parse(response.body)).to include('invitation_url', 'token')
      end
    end

    context "when user is not admin of the group" do
      before do
        # Changer le rôle de l'utilisateur à membre
        membership = group.memberships.find_by(user: user)
        membership.update(role: 'member')

        post "/api/v1/groups/#{group.id}/invitations", params: valid_attributes, headers: headers
      end

      it "returns status code 403" do
        expect(response).to have_http_status(403)
      end

      it "returns a forbidden message" do
        expect(JSON.parse(response.body)).to include('error' => 'You must be an admin to manage invitations')
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

  describe "DELETE /api/v1/invitations/:token" do
    let!(:invitation) { create(:invitation, group: group, created_by: user) }

    context "when authenticated" do
      context "when the user is the creator of the invitation" do
        before { delete "/api/v1/invitations/#{invitation.token}", headers: headers }

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the invitation" do
          expect(Invitation.find_by(id: invitation.id)).to be_nil
        end
      end

      context "when the user is an admin of the group but not the creator" do
        let(:admin_user) { create(:user) }
        let(:admin_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(admin_user)}" } }

        before do
          group.add_user(admin_user, 'admin')
          delete "/api/v1/invitations/#{invitation.token}", headers: admin_headers
        end

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the invitation" do
          expect(Invitation.find_by(id: invitation.id)).to be_nil
        end
      end

      context "when the user is not authorized" do
        let(:other_user) { create(:user) }
        let(:other_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(other_user)}" } }

        before { delete "/api/v1/invitations/#{invitation.token}", headers: other_headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to delete this invitation')
        end
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

    context "when authenticated" do
      context "when the invitation is valid and unused" do
        before { post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "adds the user to the group" do
          expect(group.users.reload).to include(new_user)
        end

        it "marks the invitation as used" do
          expect(invitation.reload.used).to be true
        end

        it "returns a success message" do
          expect(JSON.parse(response.body)).to include('message' => "You have successfully joined the group #{group.name}")
        end
      end

      context "when the invitation is already used" do
        let(:used_invitation) { create(:invitation, :used, group: group, created_by: user) }

        before { post "/api/v1/invitations/accept", params: { token: used_invitation.token }, headers: new_user_headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'This invitation has already been used')
        end
      end

      context "when the user is already a member of the group" do
        before do
          group.add_user(new_user)
          post "/api/v1/invitations/accept", params: { token: invitation.token }, headers: new_user_headers
        end

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are already a member of this group')
        end
      end

      context "when the invitation token is invalid" do
        before { post "/api/v1/invitations/accept", params: { token: 'invalid_token' }, headers: new_user_headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Invalid invitation token')
        end
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
