require 'rails_helper'

RSpec.describe GiftIdea, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:link) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(GiftIdea::STATUSES) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:for_user).class_name('User') }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe 'callbacks' do
    it 'sets default status to proposed if not specified' do
      gift_idea = build(:gift_idea, status: nil)
      gift_idea.valid?
      expect(gift_idea.status).to eq('proposed')
    end
  end

  describe 'constants' do
    it 'defines valid statuses' do
      expect(GiftIdea::STATUSES).to eq(%w[proposed buying bought])
    end
  end

  describe 'custom validations' do
    context 'when creator and receiver have common group' do
      let(:group) { create(:group) }
      let(:creator) { create(:user) }
      let(:receiver) { create(:user) }

      before do
        create(:membership, user: creator, group: group)
        create(:membership, user: receiver, group: group)
      end

      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: creator, for_user: receiver)
        expect(gift_idea).to be_valid
      end
    end

    context 'when creator and receiver have no common group' do
      let(:creator) { create(:user) }
      let(:receiver) { create(:user) }

      it 'is invalid' do
        gift_idea = build(:gift_idea, created_by: creator, for_user: receiver)
        expect(gift_idea).not_to be_valid
        expect(gift_idea.errors[:for_user]).to include("doit partager au moins un groupe avec vous")
      end
    end

    context 'when creator and receiver are the same person' do
      let(:user) { create(:user) }

      it 'is valid' do
        gift_idea = build(:gift_idea, created_by: user, for_user: user)
        expect(gift_idea).to be_valid
      end
    end
  end

  describe '#mark_as_buying' do
    let(:gift_idea) { create(:gift_idea) }

    it 'changes status to buying' do
      gift_idea.mark_as_buying
      expect(gift_idea.reload.status).to eq('buying')
    end
  end

  describe '#mark_as_bought' do
    let(:gift_idea) { create(:gift_idea, :buying) }

    it 'changes status to bought' do
      gift_idea.mark_as_bought
      expect(gift_idea.reload.status).to eq('bought')
    end
  end

  describe '#visible_to?' do
    let(:group) { create(:group) }
    let(:creator) { create(:user) }
    let(:receiver) { create(:user) }
    let(:group_member) { create(:user) }
    let(:non_group_member) { create(:user) }

    before do
      create(:membership, user: creator, group: group)
      create(:membership, user: receiver, group: group)
      create(:membership, user: group_member, group: group)
    end

    context 'when gift idea is proposed' do
      let(:gift_idea) { create(:gift_idea, created_by: creator, for_user: receiver) }

      it 'is visible to creator' do
        expect(gift_idea.visible_to?(creator)).to be true
      end

      it 'is visible to receiver' do
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
  end
end
