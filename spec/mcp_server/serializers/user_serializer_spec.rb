# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Serializers::UserSerializer do
  let(:current_user) { create(:user) }
  let(:group) { create(:group) }

  describe '.serialize_compact' do
    it 'retourne id, name, account_type' do
      user = create(:user, name: 'Alice')
      result = described_class.serialize_compact(user)
      expect(result).to eq({ id: user.id, name: 'Alice', account_type: 'standard' })
    end
  end

  describe '.serialize_full' do
    let(:target_user) { create(:user, name: 'Bob') }

    before do
      create(:membership, user: current_user, group: group)
      create(:membership, user: target_user, group: group)
    end

    it 'retourne les groupes communs' do
      result = described_class.serialize_full(target_user, current_user)
      expect(result[:common_groups]).to include({ id: group.id, name: group.name })
    end

    it 'inclut les enfants managés visibles par current_user' do
      child = create(:managed_user, parent: target_user)
      create(:membership, user: child, group: group)
      result = described_class.serialize_full(target_user, current_user)
      expect(result[:managed_children].map { |c| c[:id] }).to include(child.id)
    end

    it 'exclut les enfants managés non visibles par current_user' do
      invisible_child = create(:managed_user, parent: target_user)
      result = described_class.serialize_full(target_user, current_user)
      expect(result[:managed_children].map { |c| c[:id] }).not_to include(invisible_child.id)
    end

    it 'retourne account_type et name' do
      result = described_class.serialize_full(target_user, current_user)
      expect(result[:name]).to eq('Bob')
      expect(result[:account_type]).to eq('standard')
    end
  end
end
