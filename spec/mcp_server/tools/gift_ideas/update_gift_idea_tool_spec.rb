# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::UpdateGiftIdeaTool do
  let(:creator) { create(:user) }
  let(:server_context) { { user_id: creator.id } }

  describe '.call' do
    context 'when the gift idea exists and user is creator' do
      let!(:gift_idea) { create(:gift_idea, title: 'Vélo', created_by: creator) }

      it 'updates title and returns updated data' do
        result = described_class.call(
          server_context: server_context,
          id: gift_idea.id,
          title: 'Vélo rouge'
        )
        expect(result).not_to be_error
        expect(result.structured_content['title']).to eq('Vélo rouge')
        expect(gift_idea.reload.title).to eq('Vélo rouge')
      end

      it 'maps url param to link column' do
        described_class.call(
          server_context: server_context,
          id: gift_idea.id,
          url: 'https://example.com/velo'
        )
        expect(gift_idea.reload.link).to eq('https://example.com/velo')
      end

      it 'returns url field with frontend path' do
        result = described_class.call(server_context: server_context, id: gift_idea.id, title: 'New')
        expect(result.structured_content['url']).to eq("/gift-ideas/#{gift_idea.id}")
      end
    end

    context 'when no fields are provided' do
      let!(:gift_idea) { create(:gift_idea, title: 'Vélo', created_by: creator) }

      it 'returns an error response' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).to be_error
        parsed = JSON.parse(result.content.first[:text])
        expect(parsed['error']).to eq('No fields provided to update')
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
