# frozen_string_literal: true

# Configuration du serveur MCP (Model Context Protocol).
# Voir https://github.com/modelcontextprotocol/ruby-sdk
Rails.application.config.after_initialize do
  # Charger le namespace GiftersMcp et ses tools pour éviter un NameError au premier appel.
  GiftersMcp::Tools::ListGiftIdeasTool
  GiftersMcp::Tools::GetGiftIdeaTool
  GiftersMcp::Tools::ListGroupsTool
  GiftersMcp::Tools::SearchGiftIdeasTool
  GiftersMcp::Tools::CreateGiftIdeaTool
  GiftersMcp::Tools::UpdateGiftIdeaTool

  MCP.configure do |config|
    config.exception_reporter = lambda { |exception, server_context|
      Rails.logger.error("[MCP] #{exception.class}: #{exception.message}")
      Rails.logger.error(exception.backtrace.first(10).join("\n"))
      # Optionnel : envoyer à un service d'erreurs (Bugsnag, Sentry, etc.)
      # e.g. Sentry.capture_exception(exception, extra: { mcp_context: server_context })
    }
  end
end
