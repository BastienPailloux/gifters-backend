# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:child_user) { create(:managed_user, parent: user) }
  let(:group) { create(:group) }

  permissions :index?, :create? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, Group)
      expect(subject).to permit(other_user, Group)
    end
  end

  permissions :show? do
    context 'when user is a member of the group' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is not a member but their child is' do
      before { group.memberships.create(user: child_user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when neither user nor their child is a member' do
      it 'denies access' do
        expect(subject).not_to permit(user, group)
      end
    end
  end

  permissions :update?, :destroy? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is a regular member (not admin)' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'denies access' do
        expect(subject).not_to permit(user, group)
      end
    end

    context 'when user is not a member' do
      it 'denies access' do
        expect(subject).not_to permit(user, group)
      end
    end
  end

  permissions :manage_invitations? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is a regular member (not admin)' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'denies access' do
        expect(subject).not_to permit(user, group)
      end
    end
  end

  permissions :leave? do
   context 'when user is an admin but there are other admins' do
      let(:other_admin) { create(:user) }
      before do
        group.memberships.create(user: user, role: 'admin')
        group.memberships.create(user: other_admin, role: 'admin')
      end

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end

    context 'when user is a regular member' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, group)
      end
    end
  end

  describe 'Scope' do
    let!(:user_group) { create(:group) }
    let!(:child_group) { create(:group) }
    let!(:other_group) { create(:group) }

    before do
      user_group.memberships.create(user: user, role: 'member')
      child_group.memberships.create(user: child_user, role: 'member')
      other_group.memberships.create(user: other_user, role: 'member')
    end

    it 'returns only groups where the user is a member (not children groups)' do
      resolved = Pundit.policy_scope!(user, Group)
      expect(resolved).to include(user_group)
      expect(resolved).not_to include(child_group)
      expect(resolved).not_to include(other_group)
    end
  end
end
