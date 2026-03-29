# frozen_string_literal: true

# Stub MistralEmbeddingService globally to prevent real API calls during tests.
# Individual specs can override this stub as needed.
RSpec.configure do |config|
  config.before(:each) do
    stub_service = instance_double(MistralEmbeddingService, embed: Array.new(1024, 0.0))
    allow(MistralEmbeddingService).to receive(:new).and_return(stub_service)
  end
end
