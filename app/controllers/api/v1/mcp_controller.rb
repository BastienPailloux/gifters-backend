# frozen_string_literal: true

module Api
  module V1
    class McpController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:show]
      before_action :authenticate_user!, only: [:create]
      before_action :authorize_tool_call!, only: [:create]

      MCP_TOOL_CLASSES = [
        ::Tools::GiftIdeas::ListGiftIdeasTool,
        ::Tools::GiftIdeas::GetGiftIdeaTool,
        ::Tools::GiftIdeas::SearchGiftIdeasTool,
        ::Tools::GiftIdeas::CreateGiftIdeaTool,
        ::Tools::GiftIdeas::UpdateGiftIdeaTool,
        ::Tools::GiftIdeas::DeleteGiftIdeaTool,
        ::Tools::GiftIdeas::MarkAsBuyingTool,
        ::Tools::GiftIdeas::MarkAsBoughtTool,
        ::Tools::GiftIdeas::CancelPurchaseTool,
        ::Tools::Users::ListGroupMembersTool,
        ::Tools::Users::SearchUsersTool,
        ::Tools::Users::GetUserTool,
        ::Tools::Groups::ListGroupsTool,
        ::Tools::Groups::GetGroupTool,
        ::Tools::Groups::CreateGroupTool,
        ::Tools::Groups::UpdateGroupTool,
        ::Tools::Groups::DeleteGroupTool,
        ::Tools::Invitations::CreateInvitationTool,
        ::Tools::Memberships::RemoveMemberTool,
      ].freeze

      def show
        render json: {
          name: "gifters",
          title: "Gifters MCP Server",
          version: "1.0.0",
          protocol: "mcp",
          instructions: "Utilisez l'endpoint POST /api/v1/mcp avec un body JSON-RPC. Authentification Bearer JWT requise."
        }
      end

      def create
        server = build_mcp_server
        response_body = server.handle_json(fill_optional_params(raw_request_body))
        render json: response_body
      end

      private

      def raw_request_body
        @raw_request_body ||= begin
          request.body.rewind
          request.body.read
        end
      end

      def authorize_tool_call!
        begin
          parsed = JSON.parse(raw_request_body)
        rescue JSON::ParserError
          return
        end
        return unless parsed["method"] == "tools/call"

        tool_name = parsed.dig("params", "name")
        tool_klass = MCP_TOOL_CLASSES.find { |k| k.tool_name == tool_name }
        return unless tool_klass&.respond_to?(:authorize!)

        params = (parsed.dig("params", "arguments") || {}).symbolize_keys
        unless tool_klass.authorize!(current_user, params)
          render json: {
            jsonrpc: "2.0",
            error: { code: 4003, message: "Forbidden" },
            id: parsed["id"] || 0
          }, status: :forbidden
        end
      end

      def fill_optional_params(raw_body)
        begin
          parsed = JSON.parse(raw_body)
        rescue JSON::ParserError
          return raw_body
        end
        return raw_body unless parsed["method"] == "tools/call"

        tool_name = parsed.dig("params", "name")
        return raw_body unless tool_name

        tool_klass = MCP_TOOL_CLASSES.find { |klass| klass.tool_name == tool_name }
        return raw_body unless tool_klass

        schema   = tool_klass.input_schema_value.to_h
        required = Array(schema[:required]).map(&:to_s)
        props    = (schema[:properties] || {}).keys.map(&:to_s)
        args     = parsed.dig("params", "arguments") || {}

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
