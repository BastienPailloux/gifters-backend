# frozen_string_literal: true

module Chat
  # Orchestre un tour de chat : envoie les messages à un LLM (OpenAI) qui peut
  # appeler les outils du serveur MCP (mcp.gifters.fr) avec le JWT de l'utilisateur.
  class ChatWithMcpService
    MAX_TOOL_ROUNDS = 10

    def initialize(auth_header:, model: "gpt-4o-mini")
      @auth_header = auth_header
      @model = model
    end

    def call(messages)
      return error_response("OPENAI_API_KEY manquant") if openai_api_key.blank?

      mcp_tools = fetch_mcp_tools
      return error_response("Impossible de récupérer les outils MCP") if mcp_tools.empty?

      openai_tools = mcp_tools_to_openai_format(mcp_tools)
      openai_messages = normalize_messages(messages)
      add_system_message!(openai_messages)

      round = 0
      loop do
        round += 1
        raise "Trop d'appels d'outils" if round > MAX_TOOL_ROUNDS

        response = openai_client.chat(parameters: {
          model: @model,
          messages: openai_messages,
          tools: openai_tools,
          tool_choice: "auto"
        })

        msg = response.dig("choices", 0, "message")
        return error_response("Réponse OpenAI invalide") unless msg

        tool_calls = msg["tool_calls"]
        if tool_calls.blank?
          return { role: "assistant", content: msg["content"].to_s }
        end

        openai_messages << msg
        tool_calls.each do |tc|
          result = call_mcp_tool(mcp_tools, tc)
          openai_messages << {
            "role" => "tool",
            "tool_call_id" => tc["id"],
            "name" => tc.dig("function", "name"),
            "content" => result
          }
        end
      end
    rescue StandardError => e
      Rails.logger.error("[ChatWithMcpService] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.first(8).join("\n"))
      error_response(e.message)
    end

    private

    def openai_api_key
      @openai_api_key ||= ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
    end

    def openai_client
      @openai_client ||= OpenAI::Client.new(access_token: openai_api_key)
    end

    def mcp_server_url
      ENV.fetch("MCP_SERVER_URL", "http://mcp.lvh.me:3000")
    end

    def mcp_client
      @mcp_client ||= begin
        transport = MCP::Client::HTTP.new(
          url: mcp_server_url,
          headers: { "Authorization" => @auth_header.to_s, "Content-Type" => "application/json" }
        )
        MCP::Client.new(transport: transport)
      end
    end

    def fetch_mcp_tools
      mcp_client.tools
    end

    def mcp_tools_to_openai_format(tools)
      tools.map do |t|
        {
          type: "function",
          function: {
            name: t.name,
            description: t.description.to_s,
            parameters: (t.input_schema || {}).stringify_keys
          }
        }
      end
    end

    def normalize_messages(messages)
      Array(messages).map do |m|
        {
          "role" => m["role"] || m[:role],
          "content" => m["content"] || m[:content] || ""
        }.compact
      end
    end

    def add_system_message!(openai_messages)
      system_content = <<~TEXT
        Tu es l'assistant de l'application Gifters (gestion d'idées de cadeaux et de groupes).
        Tu peux utiliser les outils fournis pour lister les idées de cadeaux, voir le détail d'une idée, ou lister les groupes de l'utilisateur.
        Réponds de façon concise et utile en français, en t'appuyant sur les données retournées par les outils.
      TEXT
      openai_messages.unshift("role" => "system", "content" => system_content.strip)
    end

    def call_mcp_tool(mcp_tools, tool_call)
      name = tool_call.dig("function", "name")
      args_json = tool_call.dig("function", "arguments").to_s
      args = args_json.present? ? JSON.parse(args_json) : {}
      args = args.transform_keys(&:to_sym) if args.is_a?(Hash)

      tool = mcp_tools.find { |t| t.name == name }
      unless tool
        return { error: "Outil inconnu: #{name}" }.to_json
      end

      response = mcp_client.call_tool(tool: tool, arguments: args)
      contents = response.dig("result", "content") || response.dig("result", "contents") || []
      text = contents.is_a?(Array) ? contents.map { |c| c["text"] || c[:text] }.join("\n") : contents.to_s
      text.presence || response.to_json
    rescue JSON::ParserError
      { error: "Arguments invalides" }.to_json
    rescue StandardError => e
      { error: e.message }.to_json
    end

    def error_response(message)
      { role: "assistant", content: "Désolé, une erreur s’est produite : #{message}" }
    end
  end
end
