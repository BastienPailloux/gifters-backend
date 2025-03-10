require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "invitation_created" do
    let(:group) { create(:group, name: 'Test Group', description: 'A test group') }
    let(:sender) { create(:user, name: 'John Doe') }
    let(:invitation) { create(:invitation, group: group, created_by: sender) }
    let(:recipient_email) { 'recipient@example.com' }
    let(:mail) { InvitationMailer.invitation_created(invitation, recipient_email) }

    it "renders the headers" do
      expect(mail.subject).to eq("Vous avez été invité à rejoindre un groupe sur Gifters")
      expect(mail.to).to eq([recipient_email])
      expect(mail.from).to eq(["notifications@gifters.com"])
    end

    it "renders the body with sender name" do
      expect(mail.body.encoded).to match(sender.name)
    end

    it "renders the body with group name" do
      expect(mail.body.encoded).to match(group.name)
    end

    it "renders the body with group description" do
      expect(mail.body.encoded).to match(group.description)
    end

    it "renders the body with token" do
      expect(mail.body.encoded).to match(invitation.token)
    end
  end

  describe "invitation_accepted" do
    let(:group) { create(:group, name: 'Test Group') }
    let(:admin) { create(:user, name: 'Admin User', email: 'admin@example.com') }
    let(:user) { create(:user, name: 'New Member') }
    let(:invitation) { create(:invitation, group: group, created_by: admin) }
    let(:mail) { InvitationMailer.invitation_accepted(invitation, user) }

    before do
      create(:membership, user: admin, group: group, role: 'admin')
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Un utilisateur a rejoint votre groupe sur Gifters")
      expect(mail.to).to eq([admin.email])
      expect(mail.from).to eq(["notifications@gifters.com"])
    end

    it "renders the body with user name" do
      expect(mail.body.encoded).to match(user.name)
    end

    it "renders the body with group name" do
      expect(mail.body.encoded).to match(group.name)
    end
  end
end
