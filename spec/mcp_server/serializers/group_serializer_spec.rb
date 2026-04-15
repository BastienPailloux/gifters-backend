# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Serializers::GroupSerializer do
  let(:current_user) { create(:user) }
  let(:other_user)   { create(:user) }
  let(:group)        { create(:group) }

  before do
    create(:membership, user: current_user, group: group, role: 'admin')
    create(:membership, user: other_user,   group: group, role: 'member')
  end

  describe '.serialize_compact' do
    it 'retourne id, name, members_count' do
      result = described_class.serialize_compact(group)
      expect(result).to eq({
        id:            group.id,
        name:          group.name,
        members_count: 2
      })
    end
  end

  describe '.serialize_full' do
    it 'inclut current_user_role' do
      result = described_class.serialize_full(group, current_user)
      expect(result[:current_user_role]).to eq('admin')
    end

    it 'inclut la liste des membres avec leur rôle' do
      result = described_class.serialize_full(group, current_user)
      ids = result[:members].map { |m| m[:id] }
      expect(ids).to contain_exactly(current_user.id, other_user.id)
      admin = result[:members].find { |m| m[:id] == current_user.id }
      expect(admin[:role]).to eq('admin')
    end

    it 'inclut les invitations du groupe' do
      invitation = create(:invitation, group: group, created_by: current_user)
      result = described_class.serialize_full(group, current_user)
      inv_ids = result[:invitations].map { |i| i[:id] }
      expect(inv_ids).to include(invitation.id)
    end

    it 'inclut id, name, members_count' do
      result = described_class.serialize_full(group, current_user)
      expect(result[:id]).to eq(group.id)
      expect(result[:name]).to eq(group.name)
      expect(result[:members_count]).to eq(2)
    end
  end
end
