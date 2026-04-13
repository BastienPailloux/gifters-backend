# frozen_string_literal: true

module Tools
  module GiftIdeas
    class ListGroupsTool < MCP::Tool
      description "Liste les groupes dont l'utilisateur connecté est membre (famille, amis, etc.)."
      input_schema(
        type: "object",
        properties: {}
      )
      # structuredContent MCP doit être un objet (dict), pas un tableau
      output_schema(
        type: "object",
        properties: {
          groups: {
            type: "array",
            items: {
              properties: {
                id: { type: "integer" },
                name: { type: "string" },
                members_count: { type: "integer" }
              },
              required: %w[id name members_count]
            }
          }
        },
        required: %w[groups]
      )

      class << self
        def call(server_context:)
          user = user_from_context(server_context)
          scope = GroupPolicy::Scope.new(user, Group).resolve
          groups = scope.map { |g| { id: g.id, name: g.name, members_count: g.members_count } }
          groups_arr = groups.map { |h| h.transform_keys(&:to_s) }
          MCP::Tool::Response.new(
            [{ type: "text", text: groups.to_json }],
            structured_content: { "groups" => groups_arr }
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
