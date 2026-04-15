# frozen_string_literal: true

module Tools
  module Memberships
    class RemoveMemberTool < MCP::Tool
      description "Retire un membre d'un groupe. Réservé aux admins. Impossible de retirer le dernier admin."
      input_schema(
        properties: {
          group_id: { type: "integer", description: "ID du groupe" },
          user_id:  { type: "integer", description: "ID de l'utilisateur à retirer" }
        },
        required: %w[group_id user_id]
      )
      output_schema(
        type: "object",
        properties: {
          removed:  { type: "boolean" },
          user_id:  { type: "integer" },
          group_id: { type: "integer" }
        },
        required: %w[removed user_id group_id]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).manage_memberships?
        end

        def call(server_context:, group_id:, user_id:)
          user  = user_from_context(server_context)
          group = Group.find_by(id: group_id)
          return error_response("Groupe introuvable", group_id, user_id) unless group

          membership = group.memberships.find_by(user_id: user_id)
          return error_response("Cet utilisateur n'est pas membre du groupe", group_id, user_id) unless membership

          if membership.admin? && group.admin_count == 1
            return error_response("Impossible de retirer le dernier admin du groupe", group_id, user_id)
          end

          membership.destroy!
          data = { "removed" => true, "user_id" => user_id, "group_id" => group_id }
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def error_response(message, group_id, user_id)
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: message }.to_json }],
            error: true,
            structured_content: { "removed" => false, "user_id" => user_id, "group_id" => group_id }
          )
        end
      end
    end
  end
end
