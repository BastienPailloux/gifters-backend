require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }

    # Test personnalisé pour l'unicité de l'email
    it 'validates uniqueness of email' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:groups).through(:memberships) }
    it { should have_many(:created_gift_ideas).dependent(:destroy) }
    it { should have_many(:gift_recipients).dependent(:destroy) }
    it { should have_many(:received_gift_ideas).through(:gift_recipients).source(:gift_idea) }
  end

  describe '#common_groups_with' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }

    before do
      create(:membership, user: user1, group: group1)
      create(:membership, user: user1, group: group2)
      create(:membership, user: user2, group: group1)
    end

    it 'returns groups that both users are members of' do
      common_groups = user1.common_groups_with(user2)
      expect(common_groups).to include(group1)
      expect(common_groups).not_to include(group2)
    end
  end

  describe '#has_common_group_with?' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:group) { create(:group) }

    before do
      create(:membership, user: user1, group: group)
      create(:membership, user: user2, group: group)
    end

    it 'returns true if users share a group' do
      expect(user1.has_common_group_with?(user2)).to be true
    end

    it 'returns false if users do not share a group' do
      expect(user1.has_common_group_with?(user3)).to be false
    end
  end

  describe "locale attribute" do
    it "can be nil by default" do
      user = User.new
      expect(user.locale).to be_nil
    end

    it "can update locale to a valid value" do
      user = create(:user)
      user.update(locale: 'fr')
      expect(user.reload.locale).to eq('fr')
    end

    it "can be set to nil" do
      user = create(:user, locale: 'fr')
      user.update(locale: nil)
      expect(user.reload.locale).to be_nil
    end
  end
end
