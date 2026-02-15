# frozen_string_literal: true

module Api
  module V1
    # Contrôleur exposant le protocole MCP (Model Context Protocol) pour les assistants IA.
    # Les clients (ex: Cursor, Claude) envoient des requêtes JSON-RPC en POST ;
    # l'utilisateur doit être authentifié via JWT (header Authorization).
    class McpController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:show]
      before_action :authenticate_user!, only: [:create]

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
        response_body = server.handle_json(request.body.read)
        render json: response_body
      end

      private

      def build_mcp_server
        ::MCP::Server.new(
          name: "gifters",
          title: "Gifters MCP Server",
          version: "1.0.0",
          instructions: "Outils pour interagir avec l'application Gifters : idées de cadeaux et groupes.",
          tools: [
            ::GiftersMcp::Tools::ListGiftIdeasTool,
            ::GiftersMcp::Tools::GetGiftIdeaTool,
            ::GiftersMcp::Tools::ListGroupsTool
          ],
          server_context: { user_id: current_user.id }
        )
      end
    end
  end
end
