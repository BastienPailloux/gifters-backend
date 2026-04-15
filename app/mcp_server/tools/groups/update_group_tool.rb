# frozen_string_literal: true

module Tools
  module Groups
    class UpdateGroupTool < MCP::Tool
      description "Renomme un groupe. Réservé aux admins du groupe."
      input_schema(
        properties: {
          group_id: { type: "integer", description: "ID du groupe" },
          name:     { type: "string",  description: "Nouveau nom du groupe" }
        },
        required: %w[group_id name]
      )
      output_schema(
        type: "object",
        properties: {
          id:                { type: "integer" },
          name:              { type: "string" },
          members_count:     { type: "integer" },
          current_user_role: { type: "string" },
          members:           { type: "array", items: { type: "object" } },
          invitations:       { type: "array", items: { type: "object" } }
        },
        required: %w[id name members_count current_user_role members invitations]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).update?
        end

        def call(server_context:, group_id:, name:)
          user  = user_from_context(server_context)
          group = Group.find_by(id: group_id)
          return error_response("Groupe introuvable") unless group

          unless group.update(name: name)
            return error_response(group.errors.full_messages.join(', '))
          end

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
            structured_content: { "id" => 0, "name" => message, "members_count" => 0,
                                  "current_user_role" => "", "members" => [], "invitations" => [] }
          )
        end
      end
    end
  end
end
