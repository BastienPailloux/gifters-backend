# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftIdeaPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:child_user) { create(:managed_user, parent: user) }
  let(:recipient_user) { create(:user) }
  let(:group) { create(:group) }

  before do
    # Create a group with members so they can share gift ideas
    group.memberships.create(user: user, role: 'member')
    group.memberships.create(user: other_user, role: 'member')
    group.memberships.create(user: recipient_user, role: 'member')
  end

  let(:gift_idea) do
    idea = create(:gift_idea, created_by: other_user)
    idea.gift_recipients.create(user: recipient_user)
    idea
  end

  permissions :index?, :create? do
    it 'allows any authenticated user' do
      expect(subject).to permit(user, GiftIdea)
    end
  end

  permissions :show? do
    context 'when gift idea is created by the user' do
      let(:own_gift) do
        idea = create(:gift_idea, created_by: user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, own_gift)
      end
    end

    context 'when gift idea is created by the user\'s child' do
      let(:child_gift) do
        idea = create(:gift_idea, created_by: child_user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, child_gift)
      end
    end

    context 'when gift idea is for the user\'s child' do
      let(:gift_for_child) do
        idea = create(:gift_idea, created_by: other_user)
        idea.gift_recipients.create(user: child_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, gift_for_child)
      end
    end

    context 'when gift idea has no relationship to the user' do
      let(:unrelated_user) { create(:user) }
      let(:unrelated_gift) do
        idea = create(:gift_idea, created_by: unrelated_user)
        idea.gift_recipients.create(user: unrelated_user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, unrelated_gift)
      end
    end
  end

  permissions :update?, :destroy? do
    context 'when user is the creator' do
      let(:own_gift) do
        idea = create(:gift_idea, created_by: user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, own_gift)
      end
    end

    context 'when user\'s child is the creator' do
      let(:child_gift) do
        idea = create(:gift_idea, created_by: child_user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, child_gift)
      end
    end

    context 'when user is not the creator' do
      it 'denies access' do
        expect(subject).not_to permit(user, gift_idea)
      end
    end
  end

  permissions :mark_as_buying? do
    let(:proposed_gift) do
      idea = create(:gift_idea, created_by: other_user, status: 'proposed')
      idea.gift_recipients.create(user: recipient_user)
      idea
    end

    context 'when user can see the gift and is not a recipient' do
      before do
        # Make gift visible by sharing a group
        group.memberships.create(user: user, role: 'member')
      end

      it 'grants access' do
        expect(subject).to permit(user, proposed_gift)
      end
    end

    context 'when user is a recipient' do
      let(:unrelated_creator) { create(:user) }
      let(:gift_for_user) do
        # Create a separate group so the gift is visible but user is still a recipient
        separate_group = create(:group)
        separate_group.memberships.create(user: user, role: 'member')
        separate_group.memberships.create(user: unrelated_creator, role: 'member')

        idea = create(:gift_idea, created_by: unrelated_creator, status: 'proposed')
        idea.gift_recipients.create(user: user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, gift_for_user)
      end
    end

    context 'when user\'s child is a recipient' do
      let(:gift_for_child) do
        idea = create(:gift_idea, created_by: other_user, status: 'proposed')
        idea.gift_recipients.create(user: child_user)
        idea
      end

      it 'allows parent to buy gift for their child' do
        expect(subject).to permit(user, gift_for_child)
      end
    end

    context 'when gift is already bought' do
      let(:bought_gift) do
        idea = create(:gift_idea, created_by: other_user, status: 'bought')
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, bought_gift)
      end
    end
  end

  permissions :mark_as_bought? do
    let(:buying_gift) do
      idea = create(:gift_idea, created_by: other_user, status: 'buying', buyer: user)
      idea.gift_recipients.create(user: recipient_user)
      idea
    end

    context 'when user is the buyer' do
      it 'grants access' do
        expect(subject).to permit(user, buying_gift)
      end
    end

    context 'when user is the creator' do
      let(:own_gift) do
        idea = create(:gift_idea, created_by: user, status: 'proposed')
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, own_gift)
      end
    end

    context 'when user\'s child is the creator' do
      let(:child_gift) do
        idea = create(:gift_idea, created_by: child_user, status: 'proposed')
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, child_gift)
      end
    end

    context 'when gift is already bought' do
      let(:bought_gift) do
        idea = create(:gift_idea, created_by: other_user, status: 'bought')
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, bought_gift)
      end
    end
  end

  permissions :cancel_buying? do
    context 'when user is the buyer and status is buying' do
      let(:buying_gift) do
        idea = create(:gift_idea, created_by: other_user, status: 'buying', buyer: user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'grants access' do
        expect(subject).to permit(user, buying_gift)
      end
    end

    context 'when user is not the buyer' do
      let(:buying_gift) do
        idea = create(:gift_idea, created_by: other_user, status: 'buying', buyer: other_user)
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, buying_gift)
      end
    end

    context 'when status is not buying' do
      let(:proposed_gift) do
        idea = create(:gift_idea, created_by: other_user, status: 'proposed')
        idea.gift_recipients.create(user: recipient_user)
        idea
      end

      it 'denies access' do
        expect(subject).not_to permit(user, proposed_gift)
      end
    end
  end

  describe '.can_create_for_recipient?' do
    context 'when creator and recipient are the same' do
      it 'returns true' do
        expect(described_class.can_create_for_recipient?(user, user)).to be true
      end
    end

    context 'when creator and recipient share a group' do
      before do
        group.memberships.create(user: user, role: 'member')
        group.memberships.create(user: recipient_user, role: 'member')
      end

      it 'returns true' do
        expect(described_class.can_create_for_recipient?(user, recipient_user)).to be true
      end
    end

    context 'when creator is the parent of recipient' do
      it 'returns true' do
        expect(described_class.can_create_for_recipient?(user, child_user)).to be true
      end
    end

    context 'when recipient is the parent of creator (child creates for parent)' do
      it 'returns true' do
        expect(described_class.can_create_for_recipient?(child_user, user)).to be true
      end
    end

    context 'when there is no relationship' do
      let(:unrelated_user) { create(:user) }

      it 'returns false' do
        expect(described_class.can_create_for_recipient?(user, unrelated_user)).to be false
      end
    end
  end

  describe 'Scope' do
    before do
      # Ajouter child_user au groupe pour les tests de scope
      group.memberships.create(user: child_user, role: 'member')
    end

    # Un cadeau créé par user (visible directement via created_by_user)
    let!(:own_gift) do
      idea = create(:gift_idea, created_by: user)
      idea.gift_recipients.create(user: recipient_user)
      idea
    end

    # Un cadeau créé par un enfant de user
    let!(:child_created_gift) do
      idea = create(:gift_idea, created_by: child_user)
      idea.gift_recipients.create(user: recipient_user)
      idea
    end

    # Un cadeau dont un enfant de user est le destinataire
    let!(:gift_for_child) do
      idea = create(:gift_idea, created_by: other_user)
      idea.gift_recipients.create(user: child_user)
      idea
    end

    # Un cadeau sans relation avec user
    let!(:unrelated_gift) do
      unrelated_user = create(:user)
      idea = create(:gift_idea, created_by: unrelated_user)
      idea.gift_recipients.create(user: unrelated_user)
      idea
    end

    it 'returns gift ideas created by user, created by children, or for children' do
      resolved = Pundit.policy_scope!(user, GiftIdea)
      resolved_ids = resolved.pluck(:id)

      # Devrait inclure les cadeaux créés par user
      expect(resolved_ids).to include(own_gift.id)
      # Devrait inclure les cadeaux créés par les enfants
      expect(resolved_ids).to include(child_created_gift.id)
      # Devrait inclure les cadeaux pour les enfants
      expect(resolved_ids).to include(gift_for_child.id)
      # Ne devrait PAS inclure les cadeaux sans relation
      expect(resolved_ids).not_to include(unrelated_gift.id)
    end
  end
end
