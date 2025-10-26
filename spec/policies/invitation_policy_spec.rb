# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:child_user) { create(:managed_user, parent: user) }
  let(:group) { create(:group) }
  let(:invitation) { create(:invitation, group: group, created_by: other_user) }

  permissions :index? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, Invitation)
    end
  end

  permissions :show? do
    context 'when user is a member of the group' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is not a member but their child is' do
      before { group.memberships.create(user: child_user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when neither user nor their child is a member' do
      it 'denies access' do
        expect(subject).not_to permit(user, invitation)
      end
    end
  end

  permissions :create? do
    context 'when user is a member of the group' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is not a member but their child is' do
      before { group.memberships.create(user: child_user, role: 'member') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when neither user nor their child is a member' do
      it 'denies access' do
        expect(subject).not_to permit(user, invitation)
      end
    end
  end

  permissions :destroy? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is the creator of the invitation' do
      let(:own_invitation) { create(:invitation, group: group, created_by: user) }

      it 'grants access' do
        expect(subject).to permit(user, own_invitation)
      end
    end

    context 'when their child is the creator of the invitation' do
      let(:child_invitation) { create(:invitation, group: group, created_by: child_user) }

      it 'grants access' do
        expect(subject).to permit(user, child_invitation)
      end
    end

    context 'when user has no relationship to the invitation' do
      it 'denies access' do
        expect(subject).not_to permit(user, invitation)
      end
    end
  end

  permissions :send_email? do
    context 'when user is an admin of the group' do
      before { group.memberships.create(user: user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is not an admin but their child is' do
      before { group.memberships.create(user: child_user, role: 'admin') }

      it 'grants access' do
        expect(subject).to permit(user, invitation)
      end
    end

    context 'when user is a regular member (not admin)' do
      before { group.memberships.create(user: user, role: 'member') }

      it 'denies access' do
        expect(subject).not_to permit(user, invitation)
      end
    end
  end

  permissions :accept? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, invitation)
      expect(subject).to permit(other_user, invitation)
    end
  end

  describe 'Scope' do
    let!(:user_group) { create(:group) }
    let!(:child_group) { create(:group) }
    let!(:other_group) { create(:group) }

    let!(:user_invitation) { create(:invitation, group: user_group, created_by: user) }
    let!(:child_invitation) { create(:invitation, group: child_group, created_by: child_user) }
    let!(:other_invitation) { create(:invitation, group: other_group, created_by: other_user) }

    before do
      user_group.memberships.create(user: user, role: 'member')
      child_group.memberships.create(user: child_user, role: 'member')
      other_group.memberships.create(user: other_user, role: 'member')
    end

    it 'returns invitations from groups where user or their child is a member' do
      resolved = Pundit.policy_scope!(user, Invitation)
      expect(resolved).to include(user_invitation)
      expect(resolved).to include(child_invitation)
      expect(resolved).not_to include(other_invitation)
    end
  end
end
