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
    gift = build(:gift_idea,
      title: "Test Gift",
      link: "https://example.com/gift",
      created_by: creator
    )
    gift.recipients << receiver
    gift
  }

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:link) }
    it { should validate_inclusion_of(:status).in_array(GiftIdea::STATUSES) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0).allow_nil }

    context 'when validating link format' do
      it 'is invalid with an invalid URL format' do
        gift_idea = build(:gift_idea, link: 'invalid-url', created_by: creator)
        gift_idea.recipients << receiver
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:link]).to include("n'est pas une URL valide")
      end
    end
  end

  describe 'associations' do
    # Désactiver temporairement la validation personnalisée pour les tests d'association
    before do
      allow_any_instance_of(GiftIdea).to receive(:creator_and_recipients_have_common_group).and_return(true)
      allow_any_instance_of(GiftIdea).to receive(:at_least_one_recipient).and_return(true)
    end

    it { should belong_to(:created_by).class_name('User') }
    it { should have_many(:gift_recipients).dependent(:destroy) }
    it { should have_many(:recipients).through(:gift_recipients).source(:user) }
  end

  describe 'callbacks' do
    it 'sets default status to proposed if not specified' do
      gift_idea = build(:gift_idea, status: nil, created_by: creator)
      gift_idea.recipients << receiver
      gift_idea.valid?
      expect(gift_idea.status).to eq('proposed')
    end

    it 'does not override status if already set' do
      gift_idea = build(:gift_idea, status: 'buying', created_by: creator)
      gift_idea.recipients << receiver
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
    context 'when creator and recipients have common group' do
      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: creator)
        gift_idea.recipients << receiver
        expect(gift_idea).to be_valid
      end
    end

    context 'when creator and recipients have no common group' do
      let(:other_user) { create(:user) }

      it 'is invalid' do
        gift_idea = build(:gift_idea, created_by: creator)
        gift_idea.recipients << other_user
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:recipients]).to include("must all be in a common group with you")
      end
    end

    context 'when creator and recipient are the same person' do
      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: creator)
        gift_idea.recipients << creator
        expect(gift_idea).to be_valid
      end
    end

    context 'when no recipients' do
      it 'is invalid' do
        gift_idea = build(:gift_idea, created_by: creator)
        gift_idea.recipients.clear
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:base]).to include("Gift idea must have at least one recipient")
      end
    end
  end

  describe '#mark_as_buying' do
    it 'changes status to buying' do
      gift_idea = build(:gift_idea, created_by: creator)
      gift_idea.recipients << receiver
      gift_idea.save!

      gift_idea.mark_as_buying
      expect(gift_idea.reload.status).to eq('buying')
    end
  end

  describe '#mark_as_bought' do
    it 'changes status to bought' do
      gift_idea = build(:gift_idea, status: 'buying', created_by: creator)
      gift_idea.recipients << receiver
      gift_idea.save!

      gift_idea.mark_as_bought
      expect(gift_idea.reload.status).to eq('bought')
    end
  end

  describe '#visible_to?' do
    let(:group_member) { create(:user) }
    let(:non_group_member) { create(:user) }

    before do
      # S'assurer que tout le monde est dans le bon groupe
      create(:membership, user: group_member, group: group)
    end

    context 'when gift idea is proposed' do
      let!(:gift_idea) do
        # Créer un GiftIdea en désactivant les validations pour les tests
        idea = build(:gift_idea, created_by: creator)
        idea.recipients << receiver
        idea.save(validate: false)
        idea
      end

      it 'is visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be true
      end

      it 'is not visible to recipient' do
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
      let!(:gift_idea) do
        idea = build(:gift_idea, status: 'buying', created_by: creator)
        idea.recipients << receiver
        idea.save(validate: false)
        idea
      end

      it 'is visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be true
      end

      it 'is not visible to recipient' do
        expect(gift_idea.visible_to?(receiver)).to be false
      end

      it 'is visible to group members' do
        expect(gift_idea.visible_to?(group_member)).to be true
      end
    end

    context 'when gift idea is bought' do
      let!(:gift_idea) do
        idea = build(:gift_idea, status: 'bought', created_by: creator)
        idea.recipients << receiver
        idea.save(validate: false)
        idea
      end

      it 'is not visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be false
      end

      it 'is not visible to recipient' do
        expect(gift_idea.visible_to?(receiver)).to be false
      end

      it 'is not visible to group members' do
        expect(gift_idea.visible_to?(group_member)).to be false
      end
    end
  end
end
