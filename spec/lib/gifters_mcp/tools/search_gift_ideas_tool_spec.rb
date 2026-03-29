# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftersMcp::Tools::SearchGiftIdeasTool do
  let(:user) { create(:user) }
  let(:server_context) { { user_id: user.id } }
  let(:embedding_service) { instance_double(MistralEmbeddingService) }
  let(:query_vector) { Array.new(1024, 0.1) }

  before do
    allow(MistralEmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:embed).and_return(query_vector)
  end

  describe '.call' do
    context 'with matching gift ideas' do
      let!(:gift_idea) do
        recipient = create(:user)
        group = create(:group)
        create(:membership, user: user, group: group)
        create(:membership, user: recipient, group: group)
        idea = GiftIdea.new(title: 'Vélo rouge', created_by: user)
        idea.recipients = [recipient]
        idea.save!(validate: true)
        idea.update_column(:embedding, query_vector)
        idea
      end

      it 'returns matching gift ideas with url' do
        result = described_class.call(server_context: server_context, query: 'vélo')
        expect(result).not_to be_error
        results = result.structured_content['results']
        expect(results).to be_an(Array)
        expect(results.first['id']).to eq(gift_idea.id)
        expect(results.first['url']).to eq("/gift-ideas/#{gift_idea.id}")
      end

      it 'embeds the query string' do
        described_class.call(server_context: server_context, query: 'vélo rouge')
        expect(embedding_service).to have_received(:embed).with('vélo rouge')
      end
    end

    context 'with no results' do
      it 'returns an empty results array' do
        result = described_class.call(server_context: server_context, query: 'cadeau inexistant')
        expect(result.structured_content['results']).to eq([])
      end
    end
  end
end
