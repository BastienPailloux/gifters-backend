# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Invitations::CreateInvitationTool do
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
      expect(described_class.authorize!(admin, { group_id: group.id, role: 'member' })).to be true
    end

    it 'retourne false pour un simple membre' do
      expect(described_class.authorize!(member, { group_id: group.id, role: 'member' })).to be false
    end

    it 'retourne false si le groupe est introuvable' do
      expect(described_class.authorize!(admin, { group_id: 0, role: 'member' })).to be false
    end
  end

  describe '.call' do
    it 'crée une invitation' do
      expect {
        described_class.call(server_context: server_context, group_id: group.id, role: 'member')
      }.to change(Invitation, :count).by(1)
    end

    it 'retourne invitation_url' do
      result = described_class.call(server_context: server_context, group_id: group.id, role: 'member')
      expect(result).not_to be_error
      expect(result.structured_content['invitation_url']).to be_present
    end

    it 'utilise le rôle par défaut member si nil' do
      result = described_class.call(server_context: server_context, group_id: group.id, role: nil)
      expect(result).not_to be_error
      expect(Invitation.last.role).to eq('member')
    end

    it 'retourne erreur si groupe introuvable' do
      result = described_class.call(server_context: server_context, group_id: 0, role: 'member')
      expect(result).to be_error
    end
  end
end
