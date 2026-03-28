# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Conversations', type: :request do
  let(:user)    { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:other)   { create(:user) }

  describe 'GET /api/v1/conversations' do
    before do
      create(:conversation, user: user, last_activity_at: 1.hour.ago)
      create(:conversation, user: user, last_activity_at: 1.minute.ago)
      create(:conversation, user: other)
      get '/api/v1/conversations', headers: headers
    end

    it 'returns 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns only the current user conversations, most recent first' do
      data = JSON.parse(response.body)
      expect(data.size).to eq(2)
      expect(data.first['last_activity_at']).to be > data.last['last_activity_at']
    end

    it 'returns expected attributes' do
      data = JSON.parse(response.body)
      expect(data.first.keys).to include('id', 'title', 'last_activity_at', 'created_at')
    end
  end

  describe 'POST /api/v1/conversations' do
    it 'creates a conversation and returns 201' do
      expect {
        post '/api/v1/conversations', headers: headers
      }.to change(Conversation, :count).by(1)

      expect(response).to have_http_status(201)
      data = JSON.parse(response.body)
      expect(data.keys).to include('id', 'title', 'last_activity_at')
      expect(data['title']).to eq('Nouvelle conversation')
    end

    it 'returns 401 without auth' do
      post '/api/v1/conversations'
      expect(response).to have_http_status(401)
    end
  end

  describe 'GET /api/v1/conversations/:id' do
    let(:conv) { create(:conversation, user: user) }

    before do
      create(:message, conversation: conv, role: 'user', content: 'Bonjour')
      create(:message, conversation: conv, role: 'assistant', content: 'Salut')
    end

    it 'returns conversation with messages' do
      get "/api/v1/conversations/#{conv.id}", headers: headers
      expect(response).to have_http_status(200)
      data = JSON.parse(response.body)
      expect(data['messages'].size).to eq(2)
      expect(data['messages'].first.keys).to include('id', 'role', 'content', 'created_at')
    end

    it 'returns 403 for another user conversation' do
      other_conv = create(:conversation, user: other)
      get "/api/v1/conversations/#{other_conv.id}", headers: headers
      expect(response).to have_http_status(403)
    end
  end
end
