# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundMethodJob do
  describe '#perform' do
    it 'finds the record and calls the method' do
      gift_idea = create(:gift_idea)
      # generate_embedding is added in Task 4c; suppress verification until then
      RSpec::Mocks.configuration.temporarily_suppress_partial_double_verification = true
      expect_any_instance_of(GiftIdea).to receive(:generate_embedding)
      described_class.perform_now('GiftIdea', gift_idea.id, 'generate_embedding')
    ensure
      RSpec::Mocks.configuration.temporarily_suppress_partial_double_verification = false
    end
  end
end
