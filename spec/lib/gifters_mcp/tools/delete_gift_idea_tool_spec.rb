# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftersMcp::Tools::DeleteGiftIdeaTool do
  let(:creator) { create(:user) }
  let(:server_context) { { user_id: creator.id } }

  describe '.call' do
    context 'when user is the creator' do
      let!(:gift_idea) { create(:gift_idea, created_by: creator) }

      it 'deletes the gift idea' do
        expect {
          described_class.call(server_context: server_context, id: gift_idea.id)
        }.to change(GiftIdea, :count).by(-1)
      end

      it 'returns a success message with id' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content['id']).to eq(gift_idea.id)
        expect(result.structured_content['message']).to be_present
      end
    end

    context 'when gift idea does not exist' do
      it 'returns an error response' do
        result = described_class.call(server_context: server_context, id: 99999)
        expect(result).to be_error
      end
    end

    context 'when user is not authorized' do
      let(:other) { create(:user) }
      let!(:gift_idea) { create(:gift_idea, created_by: other) }

      it 'returns an error response and does not delete' do
        result = nil
        expect {
          result = described_class.call(server_context: server_context, id: gift_idea.id)
        }.not_to change(GiftIdea, :count)
        expect(result).to be_error
      end
    end
  end
end
