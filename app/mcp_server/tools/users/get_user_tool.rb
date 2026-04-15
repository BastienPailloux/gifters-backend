# frozen_string_literal: true

module Tools
  module Users
    class GetUserTool < MCP::Tool
      description "Retourne le détail d'un utilisateur visible par le current_user " \
                  "(groupes communs, enfants managés visibles)."
      input_schema(
        properties: {
          user_id: {
            type: "integer",
            description: "ID de l'utilisateur"
          }
        },
        required: ["user_id"]
      )
      output_schema(
        type: "object",
        properties: {
          id:           { type: "integer" },
          name:         { type: "string" },
          account_type: { type: "string" },
          common_groups: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:   { type: "integer" },
                name: { type: "string" }
              },
              required: %w[id name]
            }
          },
          managed_children: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:           { type: "integer" },
                name:         { type: "string" },
                account_type: { type: "string" }
              },
              required: %w[id name account_type]
            }
          }
        },
        required: %w[id name account_type common_groups managed_children]
      )

      class << self
        def authorize!(user, params)
          target = User.find_by(id: params[:user_id])
          return false unless target
          UserPolicy.new(user, target).show?
        end

        def call(server_context:, user_id:)
          current = user_from_context(server_context)
          target  = User.find_by(id: user_id)

          unless target
            return MCP::Tool::Response.new(
              [{ type: "text", text: { error: "Utilisateur introuvable" }.to_json }],
              error: true,
              structured_content: error_content
            )
          end

          raw  = Serializers::UserSerializer.serialize_full(target, current)
          data = raw.transform_keys(&:to_s)
          data["common_groups"]    = data["common_groups"].map { |g| g.transform_keys(&:to_s) }
          data["managed_children"] = data["managed_children"].map { |c| c.transform_keys(&:to_s) }

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

        def error_content
          {
            "id"               => 0,
            "name"             => "",
            "account_type"     => "standard",
            "common_groups"    => [],
            "managed_children" => []
          }
        end
      end
    end
  end
end
