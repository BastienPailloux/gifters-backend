# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Groups::DeleteGroupTool do
  let(:admin)  { create(:user) }
  let(:member) { create(:user) }
  let(:group)  { create(:group) }
  let(:server_context) { { user_id: admin.id } }

  before { create(:membership, user: admin, group: group, role: 'admin') }

  describe '.authorize!' do
    it 'retourne true pour un admin' do
      expect(described_class.authorize!(admin, { group_id: group.id })).to be true
    end

    it 'retourne false pour un non-admin' do
      create(:membership, user: member, group: group, role: 'member')
      expect(described_class.authorize!(member, { group_id: group.id })).to be false
    end

    it 'retourne false si le groupe est introuvable' do
      expect(described_class.authorize!(admin, { group_id: 0 })).to be false
    end
  end

  describe '.call' do
    context "groupe avec uniquement l'admin" do
      it 'supprime le groupe' do
        expect {
          described_class.call(server_context: server_context, group_id: group.id)
        }.to change(Group, :count).by(-1)
      end

      it 'retourne deleted: true avec group_id' do
        result = described_class.call(server_context: server_context, group_id: group.id)
        expect(result).not_to be_error
        expect(result.structured_content['deleted']).to be true
        expect(result.structured_content['group_id']).to eq(group.id)
      end
    end

    context "groupe avec d'autres membres" do
      before { create(:membership, user: member, group: group, role: 'member') }

      it 'retourne une erreur et ne supprime pas le groupe' do
        result = nil
        expect {
          result = described_class.call(server_context: server_context, group_id: group.id)
        }.not_to change(Group, :count)
        expect(result).to be_error
      end
    end

    it 'retourne erreur si groupe introuvable' do
      result = described_class.call(server_context: server_context, group_id: 0)
      expect(result).to be_error
    end
  end
end
