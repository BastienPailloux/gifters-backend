# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Groups::UpdateGroupTool do
  let(:admin)  { create(:user) }
  let(:member) { create(:user) }
  let(:group)  { create(:group) }
  let(:server_context) { { user_id: admin.id } }

  before do
    create(:membership, user: admin,  group: group, role: 'admin')
    create(:membership, user: member, group: group, role: 'member')
  end

  describe '.authorize!' do
    it 'retourne true pour un admin' do
      expect(described_class.authorize!(admin, { group_id: group.id, name: 'Nouveau' })).to be true
    end

    it 'retourne false pour un simple membre' do
      expect(described_class.authorize!(member, { group_id: group.id, name: 'Nouveau' })).to be false
    end

    it 'retourne false si le groupe est introuvable' do
      expect(described_class.authorize!(admin, { group_id: 0, name: 'Nouveau' })).to be false
    end
  end

  describe '.call' do
    it 'renomme le groupe' do
      described_class.call(server_context: server_context, group_id: group.id, name: 'Nouveau nom')
      expect(group.reload.name).to eq('Nouveau nom')
    end

    it 'retourne les détails mis à jour' do
      result = described_class.call(server_context: server_context, group_id: group.id, name: 'Nouveau nom')
      expect(result).not_to be_error
      expect(result.structured_content['name']).to eq('Nouveau nom')
    end

    it 'retourne erreur si le nom est vide' do
      result = described_class.call(server_context: server_context, group_id: group.id, name: '')
      expect(result).to be_error
    end

    it 'retourne erreur si groupe introuvable' do
      result = described_class.call(server_context: server_context, group_id: 0, name: 'X')
      expect(result).to be_error
    end
  end
end
