# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tools::Users::SearchUsersTool do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:server_context) { { user_id: user.id } }

  before { create(:membership, user: user, group: group) }

  describe '.call' do
    context 'fuzzy match' do
      let!(:alice) { create(:user, name: 'Alice Dupont') }

      before { create(:membership, user: alice, group: group) }

      it 'retourne les utilisateurs dont le nom correspond' do
        result = described_class.call(server_context: server_context, query: 'Alice')
        expect(result).not_to be_error
        ids = result.structured_content['users'].map { |u| u['id'] }
        expect(ids).to include(alice.id)
      end

      it "n'inclut pas les utilisateurs hors scope" do
        stranger = create(:user, name: 'Alice Stranger')
        result = described_class.call(server_context: server_context, query: 'Alice')
        ids = result.structured_content['users'].map { |u| u['id'] }
        expect(ids).not_to include(stranger.id)
      end

      it 'retourne id, name, account_type' do
        result = described_class.call(server_context: server_context, query: 'Alice')
        user_data = result.structured_content['users'].find { |u| u['id'] == alice.id }
        expect(user_data.keys).to contain_exactly('id', 'name', 'account_type')
      end
    end

    context 'fallback vectoriel quand aucun résultat fuzzy' do
      let(:embedding_service) { instance_double(MistralEmbeddingService) }
      let(:vector) { Array.new(1024, 0.1) }
      let!(:bob) { create(:user, name: 'Bob') }

      before do
        create(:membership, user: bob, group: group)
        bob.update_column(:embedding, vector)
        allow(MistralEmbeddingService).to receive(:new).and_return(embedding_service)
        allow(embedding_service).to receive(:embed).and_return(vector)
      end

      it 'utilise la recherche vectorielle' do
        result = described_class.call(server_context: server_context, query: 'xyz_aucun_match')
        ids = result.structured_content['users'].map { |u| u['id'] }
        expect(ids).to include(bob.id)
      end
    end

    context 'quand le fallback vectoriel échoue' do
      let(:embedding_service) { instance_double(MistralEmbeddingService) }

      before do
        allow(MistralEmbeddingService).to receive(:new).and_return(embedding_service)
        allow(embedding_service).to receive(:embed).and_raise(StandardError, 'API error')
      end

      it "retourne une liste vide sans lever d'exception" do
        result = described_class.call(server_context: server_context, query: 'xyz_aucun_match')
        expect(result).not_to be_error
        expect(result.structured_content['users']).to eq([])
      end
    end
  end
end
