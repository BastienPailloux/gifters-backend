# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Groups::CreateGroupTool do
  let(:user) { create(:user) }
  let(:server_context) { { user_id: user.id } }

  describe '.authorize!' do
    it 'retourne true pour tout utilisateur authentifié' do
      expect(described_class.authorize!(user, { name: 'Famille' })).to be true
    end
  end

  describe '.call' do
    it 'crée le groupe' do
      expect {
        described_class.call(server_context: server_context, name: 'Famille')
      }.to change(Group, :count).by(1)
    end

    it 'ajoute le créateur comme admin' do
      described_class.call(server_context: server_context, name: 'Famille')
      group = Group.last
      membership = group.memberships.find_by(user: user)
      expect(membership&.role).to eq('admin')
    end

    it 'retourne les détails du groupe créé' do
      result = described_class.call(server_context: server_context, name: 'Famille')
      expect(result).not_to be_error
      expect(result.structured_content['name']).to eq('Famille')
      expect(result.structured_content['current_user_role']).to eq('admin')
    end

    it 'retourne erreur si le nom est vide' do
      result = described_class.call(server_context: server_context, name: '')
      expect(result).to be_error
    end
  end
end
