require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:token) }
    it { should validate_uniqueness_of(:token) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(Invitation::ROLES) }
  end

  describe "associations" do
    it { should belong_to(:group) }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe "callbacks" do
    it "generates a token before validation on create" do
      invitation = build(:invitation, token: nil)
      expect(invitation.token).to be_nil
      invitation.validate
      expect(invitation.token).not_to be_nil
      expect(invitation.token.size).to eq(22) # La taille du token généré par SecureRandom.urlsafe_base64(16)
    end

    it "does not overwrite an existing token" do
      invitation = build(:invitation, token: "custom_token")
      invitation.validate
      expect(invitation.token).to eq("custom_token")
    end
  end
end
