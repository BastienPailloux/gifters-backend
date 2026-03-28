# app/services/agent_sse_proxy.rb
# frozen_string_literal: true

# Calls the agent-gifters /chat/stream endpoint and yields (event_type, data_hash)
# for each SSE event received. Uses Net::HTTP in streaming mode.
class AgentSseProxy
  AGENT_URL = -> { ENV.fetch('AGENT_URL', 'http://localhost:8000') }

  def initialize(auth_header:, messages:)
    @auth_header = auth_header.to_s
    @messages = messages
  end

  def call(&block)
    uri = URI("#{AGENT_URL.call}/chat/stream")

    Net::HTTP.start(uri.hostname, uri.port, read_timeout: 180) do |http|
      request = build_request(uri)
      http.request(request) do |response|
        stream_response(response, &block)
      end
    end
  rescue Net::ReadTimeout
    yield 'error', { 'message' => "Timeout : l'agent n'a pas répondu." }
  rescue StandardError => e
    yield 'error', { 'message' => "Erreur de connexion à l'agent : #{e.message}" }
  end

  private

  def build_request(uri)
    req = Net::HTTP::Post.new(uri)
    req['Content-Type']  = 'application/json'
    req['Authorization'] = @auth_header
    req.body = { messages: @messages }.to_json
    req
  end

  def stream_response(response, &block)
    buffer = ''
    response.read_body do |chunk|
      buffer << chunk
      while (pos = buffer.index("\n\n"))
        block_text = buffer[0...pos]
        buffer = buffer[(pos + 2)..]
        parse_sse_block(block_text, &block)
      end
    end
  end

  def parse_sse_block(text, &block)
    event_type = nil
    data       = nil

    text.each_line do |line|
      line = line.chomp
      event_type = line[7..] if line.start_with?('event: ')
      data       = JSON.parse(line[6..]) if line.start_with?('data: ')
    rescue JSON::ParserError
      # skip malformed data line
    end
    block.call(event_type, data) if event_type && data
  end
end
