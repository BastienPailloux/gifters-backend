# frozen_string_literal: true

require 'net/http'
require 'json'

class MistralEmbeddingService
  MISTRAL_API_URL = 'https://api.mistral.ai/v1/embeddings'
  MODEL = 'mistral-embed'

  def embed(text)
    api_key = ENV.fetch('MISTRAL_API_KEY')
    uri = URI(MISTRAL_API_URL)

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_key}"
    request.body = { model: MODEL, input: [text.to_s.strip] }.to_json

    response = http.request(request)
    raise "Mistral API error: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['data'][0]['embedding']
  end
end
