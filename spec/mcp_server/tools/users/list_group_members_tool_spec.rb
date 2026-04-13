# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Users::ListGroupMembersTool do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:group)      { create(:group) }
  let(:server_context) { { user_id: user.id } }

  describe '.call' do
    context "quand l'utilisateur est membre du groupe" do
      before do
        create(:membership, user: user, group: group, role: 'admin')
        create(:membership, user: other_user, group: group, role: 'member')
      end

      it 'retourne tous les membres avec leur rôle' do
        result = described_class.call(server_context: server_context, group_id: group.id)
        expect(result).not_to be_error
        members = result.structured_content['members']
        expect(members.map { |m| m['id'] }).to contain_exactly(user.id, other_user.id)
      end

      it 'inclut le rôle de chaque membre' do
        result = described_class.call(server_context: server_context, group_id: group.id)
        members = result.structured_content['members']
        admin = members.find { |m| m['id'] == user.id }
        expect(admin['role']).to eq('admin')
      end

      it 'inclut account_type' do
        result = described_class.call(server_context: server_context, group_id: group.id)
        members = result.structured_content['members']
        expect(members.first).to have_key('account_type')
      end
    end

    context "quand l'utilisateur n'est pas membre du groupe" do
      it 'retourne une erreur' do
        result = described_class.call(server_context: server_context, group_id: group.id)
        expect(result).to be_error
        expect(result.structured_content['members']).to eq([])
      end
    end

    context 'avec un groupe inexistant' do
      it 'retourne une erreur' do
        result = described_class.call(server_context: server_context, group_id: 999_999)
        expect(result).to be_error
      end
    end
  end
end
