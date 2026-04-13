# frozen_string_literal: true

module Tools
  module Users
    class SearchUsersTool < MCP::Tool
      description "Recherche des utilisateurs visibles par nom pour suggérer des destinataires. " \
                  "Recherche textuelle d'abord, puis vectorielle en fallback si aucun résultat."
      input_schema(
        properties: {
          query: {
            type: "string",
            description: "Nom ou fragment de nom à rechercher"
          }
        },
        required: ["query"]
      )
      output_schema(
        type: "object",
        properties: {
          users: {
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
        required: %w[users]
      )

      class << self
        def call(server_context:, query:)
          user  = user_from_context(server_context)
          scope = User.where(id: user.common_groups_with_users_ids)
          q     = query.to_s.strip

          # 1. Fuzzy text search
          fuzzy_results = scope.where("name ILIKE ?", "%#{q}%").limit(10).to_a
          return respond(fuzzy_results) if fuzzy_results.any?

          # 2. Vector fallback
          begin
            query_vector   = MistralEmbeddingService.new.embed(q)
            vector_results = scope.where.not(embedding: nil)
                                  .nearest_neighbors(:embedding, query_vector, distance: "cosine")
                                  .limit(5)
                                  .to_a
            respond(vector_results)
          rescue StandardError
            respond([])
          end
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def respond(users)
          data = users.map { |u| Serializers::UserSerializer.serialize_compact(u).transform_keys(&:to_s) }
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: { "users" => data }
          )
        end
      end
    end
  end
end
