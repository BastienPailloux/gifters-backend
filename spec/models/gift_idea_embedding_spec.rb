# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftIdea, 'embedding callback' do
  let(:service) { instance_double(MistralEmbeddingService) }
  let(:vector) { Array.new(1024, 0.1) }

  before do
    allow(MistralEmbeddingService).to receive(:new).and_return(service)
    allow(service).to receive(:embed).and_return(vector)
  end

  describe 'after_save callback' do
    it 'generates embedding when title changes' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      expect(service).to have_received(:embed).with('Vélo rouge')
    end

    it 'embeds title + description when both present' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge', description: 'Pour Tom')
      expect(service).to have_received(:embed).with('Vélo rouge Pour Tom')
    end

    it 'regenerates embedding when only description changes' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge', description: nil)
      allow(service).to receive(:embed).and_return(vector)
      gift_idea.update!(description: 'Pour Tom')
      expect(service).to have_received(:embed).with('Vélo rouge Pour Tom')
    end

    it 'does not regenerate embedding when only price changes' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      gift_idea.update!(price: 99.0)
      # embed called once (on create), not again
      expect(service).to have_received(:embed).once
    end

    it 'does not raise when embedding service fails' do
      allow(service).to receive(:embed).and_raise(RuntimeError, 'API error')
      expect { create(:gift_idea, title: 'Test cadeau') }.not_to raise_error
    end

    it 'stores the embedding on the gift_idea' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      expect(gift_idea.reload.embedding.to_a).to eq(vector)
    end
  end
end
