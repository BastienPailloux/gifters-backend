require 'rails_helper'

RSpec.describe GiftRecipient, type: :model do
  describe "validations" do
    it { should belong_to(:gift_idea) }
    it { should belong_to(:user) }
  end

  describe "associations" do
    it { should belong_to(:gift_idea) }
    it { should belong_to(:user) }
  end

  describe "creation" do
    let(:user) { create(:user) }
    let(:creator) { create(:user) }
    let(:gift_idea) { create(:gift_idea, created_by: creator) }

    it "can be created when valid attributes are provided" do
      gift_recipient = GiftRecipient.new(gift_idea: gift_idea, user: user)
      expect(gift_recipient).to be_valid
    end

    it "cannot be created with duplicate gift_idea and user" do
      GiftRecipient.create(gift_idea: gift_idea, user: user)
      duplicate = GiftRecipient.new(gift_idea: gift_idea, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:gift_idea_id]).to include("has already been taken")
    end

    it "validates uniqueness of gift_idea_id scoped to user_id" do
      GiftRecipient.create(gift_idea: gift_idea, user: user)

      # Même gift_idea mais user différent - devrait être valide
      other_user = create(:user)
      different_user = GiftRecipient.new(gift_idea: gift_idea, user: other_user)
      expect(different_user).to be_valid

      # Même user mais gift_idea différent - devrait être valide
      other_gift_idea = create(:gift_idea, created_by: creator)
      different_gift_idea = GiftRecipient.new(gift_idea: other_gift_idea, user: user)
      expect(different_gift_idea).to be_valid
    end
  end
end
