require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(Membership::ROLES) }

    describe 'uniqueness validation' do
      subject { create(:membership) }
      it { should validate_uniqueness_of(:user_id).scoped_to(:group_id) }
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'callbacks' do
    it 'sets default role to member if not specified' do
      membership = build(:membership, role: nil)
      membership.valid?
      expect(membership.role).to eq('member')
    end
  end

  describe 'constants' do
    it 'defines valid roles' do
      expect(Membership::ROLES).to eq(%w[member admin])
    end
  end
end
