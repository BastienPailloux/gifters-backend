# frozen_string_literal: true

# Configuration du serveur MCP (Model Context Protocol).
# Voir https://github.com/modelcontextprotocol/ruby-sdk
Rails.application.config.after_initialize do
  # Charger les tools MCP pour éviter un NameError au premier appel.
  Serializers::GiftIdeaSerializer
  Serializers::GroupSerializer
  Serializers::InvitationSerializer
  Serializers::UserSerializer
  Tools::GiftIdeas::ListGiftIdeasTool
  Tools::GiftIdeas::GetGiftIdeaTool
  Tools::GiftIdeas::SearchGiftIdeasTool
  Tools::GiftIdeas::CreateGiftIdeaTool
  Tools::GiftIdeas::UpdateGiftIdeaTool
  Tools::GiftIdeas::DeleteGiftIdeaTool
  Tools::GiftIdeas::MarkAsBuyingTool
  Tools::GiftIdeas::MarkAsBoughtTool
  Tools::GiftIdeas::CancelPurchaseTool
  Tools::Users::ListGroupMembersTool
  Tools::Users::SearchUsersTool
  Tools::Users::GetUserTool
  Tools::Groups::ListGroupsTool
  Tools::Groups::GetGroupTool
  Tools::Groups::CreateGroupTool
  Tools::Groups::UpdateGroupTool
  Tools::Groups::DeleteGroupTool
  Tools::Invitations::CreateInvitationTool
  Tools::Memberships::RemoveMemberTool

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
