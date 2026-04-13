# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::GetGiftIdeaTool do
  let(:creator)       { create(:user) }
  let(:recipient)     { create(:user, name: 'Alice') }
  let(:group)         { create(:group) }
  let(:server_context) { { user_id: creator.id } }

  before do
    create(:membership, user: creator, group: group)
    create(:membership, user: recipient, group: group)
  end

  let!(:gift_idea) do
    idea = GiftIdea.new(title: 'Livre pour Alice', created_by: creator)
    idea.recipients = [recipient]
    idea.save!
    idea
  end

  describe '.call' do
    context 'when the gift idea exists and is accessible' do
      it 'returns the gift idea details' do
        result = described_class.call(server_context: server_context, gift_idea_id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content['id']).to eq(gift_idea.id)
        expect(result.structured_content['title']).to eq('Livre pour Alice')
      end

      it 'includes gifters_url in the response' do
        result = described_class.call(server_context: server_context, gift_idea_id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content).to have_key('gifters_url')
        expect(result.structured_content['gifters_url']).to eq("/gift-ideas/#{gift_idea.id}")
      end

      it 'includes link in the response' do
        result = described_class.call(server_context: server_context, gift_idea_id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content).to have_key('link')
      end
    end

    context 'when the gift idea does not exist' do
      it 'returns an error response' do
        result = described_class.call(server_context: server_context, gift_idea_id: 0)
        expect(result).to be_error
      end
    end

  end

  describe '.authorize!' do
    let(:outsider) { create(:user) }

    it 'returns true when the user can see the gift idea' do
      result = described_class.authorize!(creator, { gift_idea_id: gift_idea.id })
      expect(result).to be true
    end

    it 'returns false when the user cannot see the gift idea' do
      result = described_class.authorize!(outsider, { gift_idea_id: gift_idea.id })
      expect(result).to be false
    end

    it 'returns false when the gift idea is not found' do
      result = described_class.authorize!(creator, { gift_idea_id: 0 })
      expect(result).to be false
    end
  end
end
