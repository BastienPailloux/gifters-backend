# frozen_string_literal: true

# Configuration du serveur MCP (Model Context Protocol).
# Voir https://github.com/modelcontextprotocol/ruby-sdk
Rails.application.config.after_initialize do
  # Charger le namespace GiftersMcp et ses tools pour éviter un NameError au premier appel.
  GiftersMcp::Serializers::GiftIdeaSerializer
  GiftersMcp::Tools::ListGiftIdeasTool
  GiftersMcp::Tools::GetGiftIdeaTool
  GiftersMcp::Tools::ListGroupsTool
  GiftersMcp::Tools::SearchGiftIdeasTool
  GiftersMcp::Tools::CreateGiftIdeaTool
  GiftersMcp::Tools::UpdateGiftIdeaTool
  GiftersMcp::Tools::DeleteGiftIdeaTool
  GiftersMcp::Tools::MarkAsBuyingTool
  GiftersMcp::Tools::MarkAsBoughtTool
  GiftersMcp::Tools::CancelPurchaseTool

  MCP.configure do |config|
    # Les paramètres optionnels absents sont injectés en nil par McpController
    # avant d'atteindre le gem, donc la validation de type JSON Schema est désactivée.
    config.validate_tool_call_arguments = false

    config.exception_reporter = lambda { |exception, server_context|
      Rails.logger.error("[MCP] #{exception.class}: #{exception.message}")
      Rails.logger.error(exception.backtrace.first(10).join("\n"))
    }
  end
end
