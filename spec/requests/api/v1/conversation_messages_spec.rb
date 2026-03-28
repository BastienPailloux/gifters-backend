# spec/requests/api/v1/conversation_messages_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::ConversationMessages', type: :request do
  let(:user)         { create(:user) }
  let(:headers)      { auth_headers(user).merge('Content-Type' => 'application/json') }
  let(:conversation) { create(:conversation, user: user) }
  let(:other_user)   { create(:user) }

  def stub_agent_proxy(steps: [], final: 'Voici ta réponse')
    allow_any_instance_of(AgentSseProxy).to receive(:call) do |_instance, &block|
      steps.each { |label| block.call('step', { 'label' => label, 'status' => 'done' }) }
      block.call('final', { 'content' => final })
    end
  end

  describe 'POST /api/v1/conversations/:conversation_id/messages/stream' do
    context 'with valid params' do
      before { stub_agent_proxy }

      it 'returns 200 with text/event-stream content type' do
        post "/api/v1/conversations/#{conversation.id}/messages/stream",
             params: { content: 'Quels sont mes cadeaux ?' }.to_json,
             headers: headers
        expect(response).to have_http_status(200)
        expect(response.content_type).to include('text/event-stream')
      end

      it 'streams the final event in the response body' do
        post "/api/v1/conversations/#{conversation.id}/messages/stream",
             params: { content: 'Quels sont mes cadeaux ?' }.to_json,
             headers: headers
        expect(response.body).to include('event: final')
        expect(response.body).to include('Voici ta réponse')
      end

      it 'saves the user message' do
        expect {
          post "/api/v1/conversations/#{conversation.id}/messages/stream",
               params: { content: 'Bonjour' }.to_json,
               headers: headers
        }.to change { conversation.messages.where(role: 'user').count }.by(1)
      end

      it 'saves the assistant message after final event' do
        post "/api/v1/conversations/#{conversation.id}/messages/stream",
             params: { content: 'Bonjour' }.to_json,
             headers: headers
        expect(conversation.messages.find_by(role: 'assistant')&.content).to eq('Voici ta réponse')
      end

      it 'updates last_activity_at on the conversation' do
        freeze_time do
          post "/api/v1/conversations/#{conversation.id}/messages/stream",
               params: { content: 'Bonjour' }.to_json,
               headers: headers
          expect(conversation.reload.last_activity_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with missing content' do
      it 'returns 422' do
        post "/api/v1/conversations/#{conversation.id}/messages/stream",
             params: { content: '' }.to_json,
             headers: headers
        expect(response).to have_http_status(422)
      end
    end

    context 'for another user conversation' do
      let(:other_conv) { create(:conversation, user: other_user) }

      it 'returns 403' do
        post "/api/v1/conversations/#{other_conv.id}/messages/stream",
             params: { content: 'Bonjour' }.to_json,
             headers: headers
        expect(response).to have_http_status(403)
      end
    end

    context 'without authentication' do
      it 'returns 401' do
        post "/api/v1/conversations/#{conversation.id}/messages/stream",
             params: { content: 'Bonjour' }.to_json
        expect(response).to have_http_status(401)
      end
    end
  end
end
