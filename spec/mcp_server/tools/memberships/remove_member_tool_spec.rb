# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Memberships::RemoveMemberTool do
  let(:admin)   { create(:user) }
  let(:member)  { create(:user) }
  let(:group)   { create(:group) }
  let(:server_context) { { user_id: admin.id } }

  before do
    create(:membership, user: admin,  group: group, role: 'admin')
    create(:membership, user: member, group: group, role: 'member')
  end

  describe '.authorize!' do
    it 'retourne true pour un admin' do
      expect(described_class.authorize!(admin, { group_id: group.id, user_id: member.id })).to be true
    end

    it 'retourne false pour un simple membre' do
      expect(described_class.authorize!(member, { group_id: group.id, user_id: admin.id })).to be false
    end

    it 'retourne false si le groupe est introuvable' do
      expect(described_class.authorize!(admin, { group_id: 0, user_id: member.id })).to be false
    end
  end

  describe '.call' do
    it 'supprime le membership du membre' do
      expect {
        described_class.call(server_context: server_context, group_id: group.id, user_id: member.id)
      }.to change(Membership, :count).by(-1)
    end

    it 'retourne removed: true avec user_id et group_id' do
      result = described_class.call(server_context: server_context, group_id: group.id, user_id: member.id)
      expect(result).not_to be_error
      expect(result.structured_content['removed']).to be true
      expect(result.structured_content['user_id']).to eq(member.id)
      expect(result.structured_content['group_id']).to eq(group.id)
    end

    context "quand la cible est le dernier admin" do
      before do
        group.memberships.find_by(user: member).destroy
      end

      it 'retourne une erreur et ne supprime pas le membership' do
        result = nil
        expect {
          result = described_class.call(server_context: server_context, group_id: group.id, user_id: admin.id)
        }.not_to change(Membership, :count)
        expect(result).to be_error
      end
    end

    it "retourne erreur si la cible n'est pas membre" do
      stranger = create(:user)
      result = described_class.call(server_context: server_context, group_id: group.id, user_id: stranger.id)
      expect(result).to be_error
    end

    it 'retourne erreur si le groupe est introuvable' do
      result = described_class.call(server_context: server_context, group_id: 0, user_id: member.id)
      expect(result).to be_error
    end
  end
end
