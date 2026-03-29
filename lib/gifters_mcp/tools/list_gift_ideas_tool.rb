# frozen_string_literal: true

module GiftersMcp
  module Tools
    class ListGiftIdeasTool < MCP::Tool
      description "Liste les idées de cadeaux visibles par l'utilisateur connecté (proposées, en cours d'achat ou achetées)."
      input_schema(
        properties: {
          status: {
            type: "string",
            enum: %w[proposed buying bought],
            description: "Filtrer par statut (optionnel)"
          },
          group_id: {
            type: "integer",
            description: "Filtrer par ID de groupe (optionnel)"
          },
          limit: {
            type: "integer",
            description: "Nombre max de résultats (défaut: 50)",
            default: 50
          }
        }
      )
      # structuredContent MCP doit être un objet (dict), pas un tableau
      output_schema(
        type: "object",
        properties: {
          ideas: {
            type: "array",
            items: {
              properties: {
                id: { type: "integer" },
                title: { type: "string" },
                status: { type: "string", enum: %w[proposed buying bought] },
                link: { type: ["string", "null"] },
                price: { type: ["number", "null"] },
                description: { type: ["string", "null"] },
                recipient_names: { type: "array", items: { type: "string" } },
                created_by_name: { type: ["string", "null"] },
                buyer_name: { type: ["string", "null"] }
              },
              required: %w[id title status]
            }
          }
        },
        required: %w[ideas]
      )

      class << self
        def call(server_context:, status: nil, group_id: nil, limit: 50)
          user = user_from_context(server_context)
          scope = GiftIdeaPolicy::Scope.new(user, GiftIdea).resolve
          scope = scope.where(status: status) if status.present?
          scope = scope.for_group(group_id) if group_id.present?
          ideas = scope.limit(limit.to_i).map { |g| serialize_gift_idea(g) }
          ideas_arr = ideas.map { |h| h.transform_keys(&:to_s) }
          MCP::Tool::Response.new(
            [{ type: "text", text: ideas.to_json }],
            structured_content: { "ideas" => ideas_arr }
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def serialize_gift_idea(g)
          {
            id: g.id,
            title: g.title,
            status: g.status,
            link: g.link,
            price: g.price.nil? ? nil : g.price.to_f,
            description: g.description,
            recipient_names: g.recipients.pluck(:name),
            created_by_name: g.created_by&.name,
            buyer_name: g.buyer&.name
          }
        end
      end
    end
  end
end
