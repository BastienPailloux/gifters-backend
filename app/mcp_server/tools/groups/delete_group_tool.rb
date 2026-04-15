# frozen_string_literal: true

module Tools
  module Groups
    class DeleteGroupTool < MCP::Tool
      description "Supprime un groupe. Réservé aux admins. Le groupe doit n'avoir aucun autre membre."
      input_schema(
        properties: {
          group_id: { type: "integer", description: "ID du groupe" }
        },
        required: %w[group_id]
      )
      output_schema(
        type: "object",
        properties: {
          deleted:  { type: "boolean" },
          group_id: { type: "integer" }
        },
        required: %w[deleted group_id]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).destroy?
        end

        def call(server_context:, group_id:)
          user  = user_from_context(server_context)
          group = Group.find_by(id: group_id)
          return error_response("Groupe introuvable", group_id) unless group

          if group.memberships.where.not(user: user).exists?
            return error_response("Impossible de supprimer un groupe avec d'autres membres", group_id)
          end

          group.destroy!
          data = { "deleted" => true, "group_id" => group_id }
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

        def error_response(message, group_id)
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: message }.to_json }],
            error: true,
            structured_content: { "deleted" => false, "group_id" => group_id }
          )
        end
      end
    end
  end
end
