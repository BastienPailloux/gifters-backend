require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:description) }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
  end

  describe '#add_user' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    it 'adds a user to the group with default role' do
      expect {
        group.add_user(user)
      }.to change(Membership, :count).by(1)

      membership = Membership.last
      expect(membership.user).to eq(user)
      expect(membership.group).to eq(group)
      expect(membership.role).to eq('member')
    end

    it 'adds a user to the group with specified role' do
      group.add_user(user, 'admin')

      membership = Membership.last
      expect(membership.role).to eq('admin')
    end
  end

  describe '#admin_users' do
    let(:group) { create(:group) }
    let(:admin_user) { create(:user) }
    let(:member_user) { create(:user) }

    before do
      create(:membership, user: admin_user, group: group, role: 'admin')
      create(:membership, user: member_user, group: group, role: 'member')
    end

    it 'returns only users with admin role' do
      admin_users = group.admin_users

      expect(admin_users).to include(admin_user)
      expect(admin_users).not_to include(member_user)
    end
  end
end
