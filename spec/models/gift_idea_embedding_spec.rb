# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftIdea, 'embedding' do
  describe 'after_save callback' do
    it 'enqueues BackgroundMethodJob when title changes' do
      expect(BackgroundMethodJob).to receive(:perform_later)
        .with('GiftIdea', anything, 'generate_embedding', [], {})
      create(:gift_idea, title: 'Vélo rouge')
    end

    it 'enqueues BackgroundMethodJob when description changes' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      expect(BackgroundMethodJob).to receive(:perform_later)
        .with('GiftIdea', gift_idea.id, 'generate_embedding', [], {})
      gift_idea.update!(description: 'Pour Tom')
    end

    it 'does not enqueue when only price changes' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      expect(BackgroundMethodJob).not_to receive(:perform_later)
      gift_idea.update!(price: 99.0)
    end
  end

  describe '#generate_embedding' do
    let(:service) { instance_double(MistralEmbeddingService) }
    let(:vector) { Array.new(1024, 0.1) }

    before do
      allow(MistralEmbeddingService).to receive(:new).and_return(service)
      allow(service).to receive(:embed).and_return(vector)
    end

    it 'calls embed with title + description' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge', description: 'Pour Tom')
      gift_idea.generate_embedding
      expect(service).to have_received(:embed).with('Vélo rouge Pour Tom')
    end

    it 'calls embed with title only when description is nil' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge', description: nil)
      gift_idea.generate_embedding
      expect(service).to have_received(:embed).with('Vélo rouge')
    end

    it 'stores the embedding on the gift_idea' do
      gift_idea = create(:gift_idea, title: 'Vélo rouge')
      gift_idea.generate_embedding
      expect(gift_idea.reload.embedding.to_a).to eq(vector)
    end

    it 'does not raise when embedding service fails' do
      allow(service).to receive(:embed).and_raise(RuntimeError, 'API error')
      gift_idea = create(:gift_idea, title: 'Test cadeau')
      expect { gift_idea.generate_embedding }.not_to raise_error
    end
  end
end
