# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MistralEmbeddingService, :real_mistral_service do
  let(:service) { described_class.new }
  let(:api_key) { 'test-mistral-key' }
  let(:text) { 'Vélo rouge pour Tom' }
  let(:embedding) { Array.new(1024) { rand } }

  before do
    stub_const('ENV', ENV.to_h.merge('MISTRAL_API_KEY' => api_key))
  end

  describe '#embed' do
    context 'when Mistral API returns 200' do
      before do
        stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
          .with(
            body: { model: 'mistral-embed', input: [text] }.to_json,
            headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{api_key}" }
          )
          .to_return(
            status: 200,
            body: { data: [{ embedding: embedding, index: 0 }] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the embedding vector' do
        result = service.embed(text)
        expect(result).to eq(embedding)
        expect(result.length).to eq(1024)
      end
    end

    context 'when Mistral API returns an error' do
      before do
        stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
          .to_return(status: 401, body: { message: 'Unauthorized' }.to_json)
      end

      it 'raises a RuntimeError' do
        expect { service.embed(text) }.to raise_error(RuntimeError, /Mistral API error: 401/)
      end
    end

    context 'when Mistral API returns malformed JSON' do
      before do
        stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
          .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises a RuntimeError about unexpected response format' do
        expect { service.embed(text) }.to raise_error(RuntimeError, /unexpected response format/)
      end
    end

    context 'when Mistral API times out' do
      before do
        stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
          .to_raise(Net::ReadTimeout)
      end

      it 'raises a RuntimeError about timeout' do
        expect { service.embed(text) }.to raise_error(RuntimeError, /timeout/)
      end
    end
  end
end
