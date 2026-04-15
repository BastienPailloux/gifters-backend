# frozen_string_literal: true

module Tools
  module Groups
    class GetGroupTool < MCP::Tool
      description "Retourne le détail d'un groupe dont l'utilisateur est membre."
      input_schema(
        properties: {
          group_id: { type: "integer", description: "ID du groupe" }
        },
        required: %w[group_id]
      )
      output_schema(
        type: "object",
        properties: {
          id:                { type: "integer" },
          name:              { type: "string" },
          members_count:     { type: "integer" },
          current_user_role: { type: "string" },
          members: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:           { type: "integer" },
                name:         { type: "string" },
                account_type: { type: "string" },
                role:         { type: "string" }
              },
              required: %w[id name account_type role]
            }
          },
          invitations: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:              { type: "integer" },
                role:            { type: "string" },
                invitation_url:  { type: "string" },
                created_by_id:   { type: "integer" },
                created_by_name: { type: "string" }
              },
              required: %w[id role invitation_url created_by_id]
            }
          }
        },
        required: %w[id name members_count current_user_role members invitations]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).show?
        end

        def call(server_context:, group_id:)
          user  = user_from_context(server_context)
          group = Group.find_by(id: group_id)
          return error_response("Groupe introuvable") unless group

          data = Serializers::GroupSerializer.serialize_full(group, user)
                                             .transform_keys(&:to_s)
          data["members"]     = data["members"].map { |m| m.transform_keys(&:to_s) }
          data["invitations"] = data["invitations"].map { |i| i.transform_keys(&:to_s) }

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

        def error_response(message)
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: message }.to_json }],
            error: true,
            structured_content: { "id" => 0, "name" => "", "members_count" => 0,
                                  "current_user_role" => "", "members" => [], "invitations" => [] }
          )
        end
      end
    end
  end
end
