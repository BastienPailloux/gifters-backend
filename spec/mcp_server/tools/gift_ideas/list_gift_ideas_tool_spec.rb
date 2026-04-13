# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::GiftIdeas::ListGiftIdeasTool do
  let(:creator) { create(:user) }
  let(:alice)   { create(:user, name: 'Alice') }
  let(:bob)     { create(:user, name: 'Bob') }
  let(:group)   { create(:group) }
  let(:server_context) { { user_id: creator.id } }

  before do
    create(:membership, user: creator, group: group)
    create(:membership, user: alice, group: group)
    create(:membership, user: bob, group: group)
  end

  def make_gift(title:, recipient:)
    idea = GiftIdea.new(title: title, created_by: creator)
    idea.recipients = [recipient]
    idea.save!
    idea
  end

  describe '.call' do
    let!(:alice_gift) { make_gift(title: 'Vélo pour Alice', recipient: alice) }
    let!(:bob_gift)   { make_gift(title: 'Livre pour Bob',  recipient: bob) }

    context 'sans filtre recipient_id' do
      it 'retourne toutes les idées visibles' do
        result = described_class.call(server_context: server_context, limit: 50)
        ids = result.structured_content['ideas'].map { |i| i['id'] }
        expect(ids).to include(alice_gift.id, bob_gift.id)
      end
    end

    context 'avec recipient_id' do
      it 'retourne uniquement les idées pour ce destinataire' do
        result = described_class.call(server_context: server_context, limit: 50, recipient_id: alice.id)
        ids = result.structured_content['ideas'].map { |i| i['id'] }
        expect(ids).to include(alice_gift.id)
        expect(ids).not_to include(bob_gift.id)
      end

      it 'retourne une liste vide si aucune idée pour ce destinataire' do
        other = create(:user)
        create(:membership, user: other, group: group)
        result = described_class.call(server_context: server_context, limit: 50, recipient_id: other.id)
        expect(result.structured_content['ideas']).to be_empty
      end
    end
  end
end
