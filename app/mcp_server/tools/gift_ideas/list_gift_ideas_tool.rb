# frozen_string_literal: true

module Tools
  module GiftIdeas
    class ListGiftIdeasTool < MCP::Tool
      description "Liste les idées de cadeaux visibles par l'utilisateur connecté. " \
                  "IMPORTANT : appeler sans aucun filtre retourne TOUTES les idées (tous groupes, tous statuts). " \
                  "N'appelle cet outil qu'UNE SEULE FOIS sans filtre pour obtenir la liste complète. " \
                  "Utilise les filtres status/group_id uniquement si l'utilisateur demande explicitement un filtre précis."
      input_schema(
        properties: {
          status: {
            type: "string",
            enum: %w[proposed buying bought],
            description: "Filtrer par statut : proposed, buying, bought (optionnel)"
          },
          group_id: {
            type: "integer",
            description: "Filtrer par ID de groupe (optionnel)"
          },
          recipient_id: {
            type: "integer",
            description: "Filtrer par ID du destinataire (optionnel)"
          },
          limit: {
            type: "integer",
            description: "Nombre max de résultats (défaut: 50)",
            default: 50
          }
        },
        required: ["limit"]
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
                gifters_url: { type: ["string", "null"] },
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
        def authorize!(_user, _params) = true

        def call(server_context:, status: nil, group_id: nil, limit: 50, recipient_id: nil)
          user = user_from_context(server_context)
          scope = GiftIdeaPolicy::Scope.new(user, GiftIdea).resolve
          scope = scope.where(status: status) if status.present?
          scope = scope.for_group(group_id) if group_id.present? && group_id.to_i > 0
          scope = scope.for_recipient(recipient_id) if recipient_id.present? && recipient_id.to_i > 0
          ideas = scope.limit(limit.to_i).map { |g| Serializers::GiftIdeaSerializer.serialize(g, user) }
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
      end
    end
  end
end
