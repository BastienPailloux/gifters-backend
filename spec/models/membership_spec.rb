require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    # Test personnalisé pour la présence du rôle
    it 'validates presence of role' do
      # Désactiver le callback before_validation pour ce test
      allow_any_instance_of(Membership).to receive(:set_default_role)

      membership = build(:membership, user: user, group: group, role: nil)
      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to include("can't be blank")
    end

    it { should validate_inclusion_of(:role).in_array(Membership::ROLES) }

    # Test personnalisé pour l'unicité de user_id dans le scope de group_id
    it 'validates uniqueness of user_id scoped to group_id' do
      create(:membership, user: user, group: group)
      duplicate = build(:membership, user: user, group: group)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("est déjà membre de ce groupe")
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    it 'sets default role to member if not specified' do
      membership = build(:membership, user: user, group: group, role: nil)
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
