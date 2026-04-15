# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Groups::ListGroupsTool do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:server_context) { { user_id: user.id } }

  describe '.authorize!' do
    it 'retourne toujours true' do
      expect(described_class.authorize!(user, {})).to be true
    end
  end

  describe '.call' do
    context "quand l'utilisateur est membre d'un groupe" do
      before { create(:membership, user: user, group: group) }

      it 'retourne les groupes dont le user est membre' do
        result = described_class.call(server_context: server_context)
        expect(result).not_to be_error
        ids = result.structured_content['groups'].map { |g| g['id'] }
        expect(ids).to include(group.id)
      end

      it 'inclut members_count' do
        result = described_class.call(server_context: server_context)
        group_data = result.structured_content['groups'].find { |g| g['id'] == group.id }
        expect(group_data).to have_key('members_count')
      end
    end

    context "quand l'utilisateur n'est membre d'aucun groupe" do
      it 'retourne une liste vide' do
        result = described_class.call(server_context: server_context)
        expect(result.structured_content['groups']).to eq([])
      end
    end
  end
end
