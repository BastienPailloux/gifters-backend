require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:groups).through(:memberships) }
    it { should have_many(:created_gift_ideas).dependent(:destroy) }
    it { should have_many(:received_gift_ideas).dependent(:destroy) }
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
end
