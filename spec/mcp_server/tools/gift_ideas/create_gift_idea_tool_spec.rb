# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::CreateGiftIdeaTool do
  let(:creator) { create(:user) }
  let(:recipient) { create(:user) }
  let(:group) { create(:group) }
  let(:server_context) { { user_id: creator.id } }

  before do
    create(:membership, user: creator, group: group)
    create(:membership, user: recipient, group: group)
  end

  describe '.call' do
    context 'with valid params' do
      it 'creates a gift idea and returns it with url' do
        result = described_class.call(
          server_context: server_context,
          title: 'Vélo rouge',
          recipient_ids: [recipient.id]
        )
        expect(result).not_to be_error
        content = result.structured_content
        expect(content['title']).to eq('Vélo rouge')
        expect(content['status']).to eq('proposed')
        expect(content['url']).to match(%r{/gift-ideas/\d+})
      end

      it 'saves the gift idea to the database' do
        expect {
          described_class.call(
            server_context: server_context,
            title: 'Vélo rouge',
            recipient_ids: [recipient.id]
          )
        }.to change(GiftIdea, :count).by(1)
      end

      it 'sets optional fields when provided' do
        described_class.call(
          server_context: server_context,
          title: 'Vélo rouge',
          recipient_ids: [recipient.id],
          description: 'Cadeau sympa',
          price: 150.0,
          url: 'https://example.com/velo'
        )
        idea = GiftIdea.last
        expect(idea.description).to eq('Cadeau sympa')
        expect(idea.price).to eq(150.0)
        expect(idea.link).to eq('https://example.com/velo')
      end
    end

    context 'with invalid recipient (no common group)' do
      let(:stranger) { create(:user) }

      it 'returns an error response' do
        result = described_class.call(
          server_context: server_context,
          title: 'Cadeau',
          recipient_ids: [stranger.id]
        )
        expect(result).to be_error
      end
    end

    context 'with missing required params' do
      it 'returns an error when title is blank' do
        result = described_class.call(
          server_context: server_context,
          title: '',
          recipient_ids: [recipient.id]
        )
        expect(result).to be_error
      end
    end
  end
end
