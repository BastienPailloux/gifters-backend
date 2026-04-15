# frozen_string_literal: true

module Tools
  module Groups
    class ListGroupsTool < MCP::Tool
      description "Liste les groupes dont l'utilisateur connecté est membre (famille, amis, etc.)."
      input_schema(
        type: "object",
        properties: {}
      )
      output_schema(
        type: "object",
        properties: {
          groups: {
            type: "array",
            items: {
              properties: {
                id:            { type: "integer" },
                name:          { type: "string" },
                members_count: { type: "integer" }
              },
              required: %w[id name members_count]
            }
          }
        },
        required: %w[groups]
      )

      class << self
        def authorize!(_user, _params) = true

        def call(server_context:)
          user   = user_from_context(server_context)
          scope  = GroupPolicy::Scope.new(user, Group).resolve
          groups = scope.map { |g| Serializers::GroupSerializer.serialize_compact(g).transform_keys(&:to_s) }
          MCP::Tool::Response.new(
            [{ type: "text", text: { groups: groups }.to_json }],
            structured_content: { "groups" => groups }
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
