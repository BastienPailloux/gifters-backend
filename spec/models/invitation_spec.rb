require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "validations" do
    # Nous ne pouvons pas tester validate_presence_of(:token) car le token est généré automatiquement
    # Nous ne pouvons pas tester validate_uniqueness_of(:token) car le token est généré automatiquement
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(Invitation::ROLES) }
    it { should validate_inclusion_of(:used).in_array([true, false]) }
  end

  describe "associations" do
    it { should belong_to(:group) }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe "callbacks" do
    it "generates a token before validation on create" do
      invitation = build(:invitation, token: nil)
      expect(invitation.token).to be_nil
      invitation.valid?
      expect(invitation.token).not_to be_nil
    end

    it "does not override an existing token" do
      invitation = build(:invitation, token: "custom_token")
      invitation.valid?
      expect(invitation.token).to eq("custom_token")
    end
  end

  describe "scopes" do
    it "returns only unused invitations" do
      used_invitation = create(:invitation, :used)
      unused_invitation = create(:invitation)

      expect(Invitation.unused).to include(unused_invitation)
      expect(Invitation.unused).not_to include(used_invitation)
    end
  end

  describe "#mark_as_used!" do
    it "marks the invitation as used" do
      invitation = create(:invitation)
      expect(invitation.used).to be false

      invitation.mark_as_used!
      expect(invitation.reload.used).to be true
    end
  end
end
