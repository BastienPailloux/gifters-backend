# frozen_string_literal: true

module Api
  module V1
    # Contrôleur exposant le protocole MCP (Model Context Protocol) pour les assistants IA.
    # Les clients (ex: Cursor, Claude) envoient des requêtes JSON-RPC en POST ;
    # l'utilisateur doit être authentifié via JWT (header Authorization).
    class McpController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:show]
      before_action :authenticate_user!, only: [:create]

      MCP_TOOL_CLASSES = [
        ::GiftersMcp::Tools::ListGiftIdeasTool,
        ::GiftersMcp::Tools::GetGiftIdeaTool,
        ::GiftersMcp::Tools::ListGroupsTool,
        ::GiftersMcp::Tools::SearchGiftIdeasTool,
        ::GiftersMcp::Tools::CreateGiftIdeaTool,
        ::GiftersMcp::Tools::UpdateGiftIdeaTool,
        ::GiftersMcp::Tools::DeleteGiftIdeaTool,
        ::GiftersMcp::Tools::MarkAsBuyingTool,
        ::GiftersMcp::Tools::MarkAsBoughtTool,
        ::GiftersMcp::Tools::CancelPurchaseTool,
      ].freeze

      # GET /api/v1/mcp — métadonnées / découverte (optionnel, sans auth pour info)
      def show
        render json: {
          name: "gifters",
          title: "Gifters MCP Server",
          version: "1.0.0",
          protocol: "mcp",
          instructions: "Utilisez l'endpoint POST /api/v1/mcp avec un body JSON-RPC. Authentification Bearer JWT requise."
        }
      end

      # POST /api/v1/mcp — requêtes JSON-RPC MCP (Streamable HTTP)
      def create
        server = build_mcp_server
        response_body = server.handle_json(fill_optional_params(request.body.read))
        render json: response_body
      end

      private

      # Injecte nil pour les paramètres optionnels absents d'un appel tools/call.
      # Cela permet aux clients de ne pas passer explicitement les params facultatifs.
      def fill_optional_params(raw_body)
        parsed = JSON.parse(raw_body)
        return raw_body unless parsed["method"] == "tools/call"

        tool_name = parsed.dig("params", "name")
        return raw_body unless tool_name

        tool_klass = MCP_TOOL_CLASSES.find { |klass| klass.tool_name == tool_name }
        return raw_body unless tool_klass

        schema    = tool_klass.input_schema_value.to_h
        required  = Array(schema[:required]).map(&:to_s)
        props     = (schema[:properties] || {}).keys.map(&:to_s)
        args      = parsed.dig("params", "arguments") || {}

        optional_missing = props - required - args.keys.map(&:to_s)
        return raw_body if optional_missing.empty?

        optional_missing.each { |p| args[p] = nil }
        parsed["params"]["arguments"] = args
        parsed.to_json
      end

      def build_mcp_server
        ::MCP::Server.new(
          name: "gifters",
          title: "Gifters MCP Server",
          version: "1.0.0",
          instructions: "Outils pour interagir avec l'application Gifters : idées de cadeaux et groupes.",
          tools: MCP_TOOL_CLASSES,
          server_context: { user_id: current_user.id }
        )
      end
    end
  end
end
