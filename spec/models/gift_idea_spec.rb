require 'rails_helper'

RSpec.describe GiftIdea, type: :model do
  # Créer des utilisateurs et un groupe partagé pour les tests
  let(:creator) { create(:user) }
  let(:receiver) { create(:user) }
  let(:group) { create(:group) }

  before do
    # S'assurer que les utilisateurs partagent un groupe
    create(:membership, user: creator, group: group)
    create(:membership, user: receiver, group: group)
  end

  # Sujet valide pour les tests de validation
  subject {
    build(:gift_idea,
      title: "Test Gift",
      link: "https://example.com/gift",
      created_by: creator,
      for_user: receiver
    )
  }

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:link) }
    it { should validate_inclusion_of(:status).in_array(GiftIdea::STATUSES) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0).allow_nil }

    context 'when validating link format' do
      it 'is invalid with an invalid URL format' do
        gift_idea = build(:gift_idea, link: 'invalid-url', created_by: creator, for_user: receiver)
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:link]).to include("n'est pas une URL valide")
      end
    end
  end

  describe 'associations' do
    # Désactiver temporairement la validation personnalisée pour les tests d'association
    before do
      allow_any_instance_of(GiftIdea).to receive(:creator_and_receiver_have_common_group).and_return(true)
    end

    it { should belong_to(:for_user).class_name('User') }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe 'callbacks' do
    it 'sets default status to proposed if not specified' do
      gift_idea = build(:gift_idea, status: nil, created_by: creator, for_user: receiver)
      gift_idea.valid?
      expect(gift_idea.status).to eq('proposed')
    end

    it 'does not override status if already set' do
      gift_idea = build(:gift_idea, status: 'buying', created_by: creator, for_user: receiver)
      gift_idea.valid?
      expect(gift_idea.status).to eq('buying')
    end
  end

  describe 'constants' do
    it 'defines valid statuses' do
      expect(GiftIdea::STATUSES).to eq(%w[proposed buying bought])
    end
  end

  describe 'custom validations' do
    context 'when creator and receiver have common group' do
      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: creator, for_user: receiver)
        expect(gift_idea).to be_valid
      end
    end

    context 'when creator and receiver have no common group' do
      let(:other_user) { create(:user) }

      it 'is invalid' do
        gift_idea = build(:gift_idea, created_by: creator, for_user: other_user)
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:for_user]).to include("doit partager au moins un groupe avec vous")
      end
    end

    context 'when creator and receiver are the same person' do
      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: creator, for_user: creator)
        expect(gift_idea).to be_valid
      end
    end
  end

  describe '#mark_as_buying' do
    it 'changes status to buying' do
      gift_idea = create(:gift_idea, created_by: creator, for_user: receiver)
      gift_idea.mark_as_buying
      expect(gift_idea.reload.status).to eq('buying')
    end
  end

  describe '#mark_as_bought' do
    it 'changes status to bought' do
      gift_idea = create(:gift_idea, :buying, created_by: creator, for_user: receiver)
      gift_idea.mark_as_bought
      expect(gift_idea.reload.status).to eq('bought')
    end
  end

  describe '#visible_to?' do
    let(:group_member) { create(:user) }
    let(:non_group_member) { create(:user) }

    before do
      create(:membership, user: group_member, group: group)
    end

    context 'when gift idea is proposed' do
      let(:gift_idea) { create(:gift_idea, created_by: creator, for_user: receiver) }

      it 'is visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be true
      end

      it 'is not visible to receiver' do
        expect(gift_idea.visible_to?(receiver)).to be false
      end

      it 'is visible to group members' do
        expect(gift_idea.visible_to?(group_member)).to be true
      end

      it 'is not visible to non-group members' do
        expect(gift_idea.visible_to?(non_group_member)).to be false
      end
    end

    context 'when gift idea is buying' do
      let(:gift_idea) { create(:gift_idea, :buying, created_by: creator, for_user: receiver) }

      it 'is visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be true
      end

      it 'is not visible to receiver' do
        expect(gift_idea.visible_to?(receiver)).to be false
      end

      it 'is visible to group members' do
        expect(gift_idea.visible_to?(group_member)).to be true
      end
    end

    context 'when gift idea is bought' do
      let(:gift_idea) { create(:gift_idea, :bought, created_by: creator, for_user: receiver) }

      it 'is not visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be false
      end

      it 'is not visible to receiver' do
        expect(gift_idea.visible_to?(receiver)).to be false
      end

      it 'is not visible to group members' do
        expect(gift_idea.visible_to?(group_member)).to be false
      end
    end
  end
end
