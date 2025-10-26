# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:child_user) { create(:managed_user, parent: user) }
  let(:shared_user) { create(:user) }
  let(:group) { create(:group) }

  permissions :index?, :shared_users? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, User)
    end
  end

  permissions :show? do
    context 'when viewing own profile' do
      it 'grants access' do
        expect(subject).to permit(user, user)
      end
    end

    context 'when viewing a user who shares a group' do
      before do
        group.memberships.create(user: user, role: 'member')
        group.memberships.create(user: shared_user, role: 'member')
      end

      it 'grants access' do
        expect(subject).to permit(user, shared_user)
      end
    end

    context 'when viewing a user who shares a group with user\'s child' do
      before do
        group.memberships.create(user: child_user, role: 'member')
        group.memberships.create(user: shared_user, role: 'member')
      end

      it 'grants access' do
        expect(subject).to permit(user, shared_user)
      end
    end

    context 'when viewing an unrelated user' do
      it 'denies access' do
        expect(subject).not_to permit(user, other_user)
      end
    end
  end

  permissions :update?, :destroy?, :update_locale? do
    context 'when viewing own profile' do
      it 'grants access' do
        expect(subject).to permit(user, user)
      end
    end

    context 'when viewing another user\'s profile' do
      it 'denies access' do
        expect(subject).not_to permit(user, other_user)
      end
    end
  end

  permissions :create_child?, :index_children? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, User)
    end
  end

  permissions :show_child?, :update_child?, :destroy_child? do
    context 'when user is the parent' do
      it 'grants access' do
        expect(subject).to permit(user, child_user)
      end
    end

    context 'when user is not the parent' do
      let(:other_child) { create(:managed_user, parent: other_user) }

      it 'denies access' do
        expect(subject).not_to permit(user, other_child)
      end
    end
  end

  describe 'Scope' do
    let!(:shared_group_user) { create(:user) }
    let!(:child_shared_user) { create(:user) }
    let!(:unrelated_user) { create(:user) }

    before do
      # User shares a group with shared_group_user
      group.memberships.create(user: user, role: 'member')
      group.memberships.create(user: shared_group_user, role: 'member')

      # Child shares a group with child_shared_user
      child_group = create(:group)
      child_group.memberships.create(user: child_user, role: 'member')
      child_group.memberships.create(user: child_shared_user, role: 'member')
    end

    it 'returns user, users sharing groups with user, and users sharing groups with children' do
      resolved = Pundit.policy_scope!(user, User)

      expect(resolved).to include(user)
      expect(resolved).to include(shared_group_user)
      expect(resolved).to include(child_shared_user)
      expect(resolved).to include(child_user)
      expect(resolved).not_to include(unrelated_user)
    end
  end
end
