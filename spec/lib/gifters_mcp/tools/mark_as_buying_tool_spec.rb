# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftersMcp::Tools::MarkAsBuyingTool do
  let(:buyer) { create(:user) }
  let(:recipient) { create(:user) }
  let(:group) { create(:group) }
  let(:server_context) { { user_id: buyer.id } }

  before do
    create(:membership, user: buyer, group: group)
    create(:membership, user: recipient, group: group)
  end

  describe '.call' do
    context 'when gift idea is proposed and user can buy' do
      let!(:gift_idea) do
        idea = build(:gift_idea, status: 'proposed', created_by: create(:user))
        idea.recipients = [recipient]
        idea.save!(validate: false)
        idea
      end

      it 'transitions status to buying' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).not_to be_error
        expect(result.structured_content['status']).to eq('buying')
        expect(gift_idea.reload.status).to eq('buying')
      end

      it 'returns url field' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result.structured_content['url']).to eq("/gift-ideas/#{gift_idea.id}")
      end
    end

    context 'when user is a recipient' do
      let!(:gift_idea) do
        idea = build(:gift_idea, status: 'proposed')
        idea.recipients = [buyer]
        idea.save!(validate: false)
        idea
      end

      it 'returns an error (recipient cannot buy)' do
        result = described_class.call(server_context: server_context, id: gift_idea.id)
        expect(result).to be_error
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
