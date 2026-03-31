# frozen_string_literal: true

module GiftersMcp
  module Tools
    class SearchGiftIdeasTool < MCP::Tool
      description "Cherche des idées de cadeaux par nom ou description approximatifs (recherche sémantique). " \
                  "À utiliser avant toute action nécessitant l'ID d'une idée."
      input_schema(
        properties: {
          query: {
            type: "string",
            description: "Texte libre décrivant l'idée de cadeau recherchée (nom approx., destinataire, etc.)"
          }
        },
        required: ["query"]
      )
      output_schema(
        type: "object",
        properties: {
          results: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id:          { type: "integer" },
                title:       { type: "string" },
                status:      { type: "string" },
                description: { type: ["string", "null"] },
                url:         { type: "string" }
              },
              required: %w[id title status url]
            }
          }
        },
        required: %w[results]
      )

      class << self
        def call(server_context:, query:)
          user = user_from_context(server_context)
          query_vector = MistralEmbeddingService.new.embed(query.to_s.strip)

          base_scope = GiftIdeaPolicy::Scope.new(user, GiftIdea).resolve
                                            .where.not(embedding: nil)
          results = base_scope
                      .nearest_neighbors(:embedding, query_vector, distance: "cosine")
                      .limit(5)
                      .map { |g| GiftersMcp::Serializers::GiftIdeaSerializer.serialize_compact(g, user) }

          MCP::Tool::Response.new(
            [{ type: "text", text: results.to_json }],
            structured_content: { "results" => results.map { |h| h.transform_keys(&:to_s) } }
          )
        rescue StandardError => e
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: e.message }.to_json }],
            error: true,
            structured_content: { "results" => [] }
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
