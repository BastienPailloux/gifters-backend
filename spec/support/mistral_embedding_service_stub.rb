# frozen_string_literal: true

# Stub MistralEmbeddingService globally to prevent real API calls during tests.
# Individual specs can opt out with metadata: `:real_mistral_service`.
RSpec.configure do |config|
  config.before(:each) do |example|
    next if example.metadata[:real_mistral_service]

    stub_service = instance_double(MistralEmbeddingService, embed: Array.new(1024, 0.0))
    allow(MistralEmbeddingService).to receive(:new).and_return(stub_service)
  end
end
