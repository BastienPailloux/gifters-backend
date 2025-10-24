# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembershipPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:child_user) { create(:managed_user, parent: user) }
  let(:group) { create(:group) }
  let(:membership) { group.memberships.create(user: other_user, role: 'member') }

  permissions :index? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, Membership)
    end
  end

  permissions :show? do
    context 'when user is a member of the same group' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when user is not a member but their child is' do
      before { group.memberships.create(user: child_user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when neither user nor their child is a member' do
      it 'denies access' do
        expect(subject).not_to permit(user, membership)
      end
    end
  end

  permissions :create?, :update? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when user is a regular member (not admin)' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'denies access' do
        expect(subject).not_to permit(user, membership)
      end
    end
  end

  permissions :destroy? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, membership)
      end
    end

    context 'when it is the user\'s own membership' do
      let(:own_membership) { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, own_membership)
      end
    end

    context 'when it is their child\'s membership' do
      let(:child_membership) { group.memberships.create(user: child_user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, child_membership)
      end
    end

    context 'when user has no relationship to the membership' do
      it 'denies access' do
        expect(subject).not_to permit(user, membership)
      end
    end
  end

  describe 'Scope' do
    let!(:user_group) { create(:group) }
    let!(:child_group) { create(:group) }
    let!(:other_group) { create(:group) }

    let!(:user_membership) { user_group.memberships.create(user: user, role: 'member') }
    let!(:child_membership) { child_group.memberships.create(user: child_user, role: 'member') }
    let!(:other_membership) { other_group.memberships.create(user: other_user, role: 'member') }

    it 'returns memberships from groups where user or their child is a member' do
      resolved = Pundit.policy_scope!(user, Membership)
      expect(resolved).to include(user_membership)
      expect(resolved).to include(child_membership)
      expect(resolved).not_to include(other_membership)
    end
  end
end
