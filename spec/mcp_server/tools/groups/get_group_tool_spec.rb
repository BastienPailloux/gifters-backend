# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Groups::GetGroupTool do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:group)      { create(:group) }
  let(:server_context) { { user_id: user.id } }

  before { create(:membership, user: user, group: group, role: 'admin') }

  describe '.authorize!' do
    it 'retourne true si le user est membre' do
      expect(described_class.authorize!(user, { group_id: group.id })).to be true
    end

    it 'retourne false si le user n\'est pas membre' do
      stranger = create(:user)
      expect(described_class.authorize!(stranger, { group_id: group.id })).to be false
    end

    it 'retourne false si le groupe est introuvable' do
      expect(described_class.authorize!(user, { group_id: 0 })).to be false
    end
  end

  describe '.call' do
    before { create(:membership, user: other_user, group: group, role: 'member') }

    it 'retourne les détails du groupe' do
      result = described_class.call(server_context: server_context, group_id: group.id)
      expect(result).not_to be_error
      expect(result.structured_content['id']).to eq(group.id)
      expect(result.structured_content['name']).to eq(group.name)
    end

    it 'inclut current_user_role' do
      result = described_class.call(server_context: server_context, group_id: group.id)
      expect(result.structured_content['current_user_role']).to eq('admin')
    end

    it 'inclut la liste des membres' do
      result = described_class.call(server_context: server_context, group_id: group.id)
      ids = result.structured_content['members'].map { |m| m['id'] }
      expect(ids).to contain_exactly(user.id, other_user.id)
    end

    it 'retourne erreur si groupe introuvable' do
      result = described_class.call(server_context: server_context, group_id: 0)
      expect(result).to be_error
    end
  end
end
