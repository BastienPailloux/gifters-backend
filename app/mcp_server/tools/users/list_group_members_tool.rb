# frozen_string_literal: true

module Tools
  module Users
    class ListGroupMembersTool < MCP::Tool
      description "Liste les membres d'un groupe dont l'utilisateur connecté est membre."
      input_schema(
        properties: {
          group_id: {
            type: "integer",
            description: "ID du groupe"
          }
        },
        required: ["group_id"]
      )
      output_schema(
        type: "object",
        properties: {
          members: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:           { type: "integer" },
                name:         { type: "string" },
                role:         { type: "string" },
                account_type: { type: "string" }
              },
              required: %w[id name role account_type]
            }
          }
        },
        required: %w[members]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).show_memberships?
        end

        def call(server_context:, group_id:)
          user  = user_from_context(server_context)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: group_id)
          return MCP::Tool::Response.new(
            [{ type: "text", text: { error: "Groupe introuvable" }.to_json }],
            error: true,
            structured_content: { "members" => [] }
          ) unless group

          members = group.memberships.includes(:user).map do |m|
            {
              "id"           => m.user.id,
              "name"         => m.user.name,
              "role"         => m.role,
              "account_type" => m.user.account_type
            }
          end

          MCP::Tool::Response.new(
            [{ type: "text", text: { members: members }.to_json }],
            structured_content: { "members" => members }
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end
      end
    end
  end
end
