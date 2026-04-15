# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Users::GetUserTool do
  let(:current_user) { create(:user) }
  let(:target_user)  { create(:user, name: 'Bob') }
  let(:group)        { create(:group) }
  let(:server_context) { { user_id: current_user.id } }

  describe '.call' do
    context "quand la cible est visible par current_user" do
      before do
        create(:membership, user: current_user, group: group)
        create(:membership, user: target_user, group: group)
      end

      it "retourne les détails de l'utilisateur" do
        result = described_class.call(server_context: server_context, user_id: target_user.id)
        expect(result).not_to be_error
        content = result.structured_content
        expect(content['id']).to eq(target_user.id)
        expect(content['name']).to eq('Bob')
        expect(content['account_type']).to eq('standard')
      end

      it 'inclut les groupes communs' do
        result = described_class.call(server_context: server_context, user_id: target_user.id)
        group_ids = result.structured_content['common_groups'].map { |g| g['id'] }
        expect(group_ids).to include(group.id)
      end

      it 'inclut les enfants managés visibles' do
        child = create(:managed_user, parent: target_user)
        create(:membership, user: child, group: group)
        result = described_class.call(server_context: server_context, user_id: target_user.id)
        child_ids = result.structured_content['managed_children'].map { |c| c['id'] }
        expect(child_ids).to include(child.id)
      end

      it 'exclut les enfants managés non visibles' do
        _invisible_child = create(:managed_user, parent: target_user)
        result = described_class.call(server_context: server_context, user_id: target_user.id)
        child_ids = result.structured_content['managed_children'].map { |c| c['id'] }
        expect(child_ids).to be_empty
      end
    end

  end

  describe '.authorize!' do
    context "when target is visible by current_user" do
      before do
        create(:membership, user: current_user, group: group)
        create(:membership, user: target_user, group: group)
      end

      it 'returns true' do
        expect(described_class.authorize!(current_user, { user_id: target_user.id })).to be true
      end
    end

    context "when target is not visible" do
      it 'returns false' do
        stranger = create(:user)
        expect(described_class.authorize!(current_user, { user_id: stranger.id })).to be false
      end
    end

    it 'returns false when user not found' do
      expect(described_class.authorize!(current_user, { user_id: 0 })).to be false
    end
  end
end
