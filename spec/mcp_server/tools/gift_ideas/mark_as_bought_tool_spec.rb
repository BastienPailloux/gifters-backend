# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::MarkAsBoughtTool do
  let(:buyer) { create(:user) }
  let(:server_context) { { user_id: buyer.id } }

  describe '.call' do
    context 'when gift idea is in buying status and user is buyer' do
      let!(:gift_idea) { create(:gift_idea, status: 'buying', buyer: buyer) }

      it 'transitions status to bought' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content['status']).to eq('bought')
        expect(gift_idea.reload.status).to eq('bought')
      end

      it 'returns url field' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result.structured_content['url']).to eq("/gift-ideas/#{gift_idea.id}")
      end
    end

    context 'when gift idea does not exist' do
      it 'returns an error response' do
        result = described_class.call(server_context: server_context, id: 99999)
        expect(result).to be_error
      end
    end

  end
end
