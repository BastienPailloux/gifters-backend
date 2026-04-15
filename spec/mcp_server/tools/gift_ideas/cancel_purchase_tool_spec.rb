# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::CancelPurchaseTool do
  let(:buyer) { create(:user) }
  let(:server_context) { { user_id: buyer.id } }

  describe '.call' do
    context 'when gift idea is buying and user is buyer' do
      let!(:gift_idea) { create(:gift_idea, status: 'buying', buyer: buyer) }

      it 'reverts status to proposed' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content['status']).to eq('proposed')
        gift_idea.reload
        expect(gift_idea.status).to eq('proposed')
        expect(gift_idea.buyer).to be_nil
      end

      it 'returns url field' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result.structured_content['url']).to eq("/gift-ideas/#{gift_idea.id}")
      end
    end

    context 'when gift idea is bought and user is buyer' do
      let!(:gift_idea) { create(:gift_idea, status: 'bought', buyer: buyer) }

      it 'reverts status to proposed' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).not_to be_error
        expect(gift_idea.reload.status).to eq('proposed')
      end
    end

    context 'when gift idea does not exist' do
      it 'returns an error response' do
        result = described_class.call(server_context: server_context, id: 99999)
        expect(result).to be_error
      end
    end
  end

  describe '.authorize!' do
    let(:buyer) { create(:user) }
    let(:other) { create(:user) }
    let(:group) { create(:group) }
    let!(:gift_idea) do
      create(:membership, user: buyer, group: group)
      recipient = create(:user).tap { |u| create(:membership, user: u, group: group) }
      idea = GiftIdea.new(title: 'Test', created_by: buyer, status: 'buying', buyer: buyer)
      idea.recipients = [recipient]
      idea.save!
      idea
    end

    it 'returns true for the buyer' do
      expect(described_class.authorize!(buyer, { id: gift_idea.id })).to be true
    end

    it 'returns false for a non-buyer' do
      expect(described_class.authorize!(other, { id: gift_idea.id })).to be false
    end

    it 'returns false when gift idea not found' do
      expect(described_class.authorize!(buyer, { id: 0 })).to be false
    end
  end
end
