# frozen_string_literal: true

module GiftersMcp
  module Tools
    class DeleteGiftIdeaTool < MCP::Tool
      description "Supprime définitivement une idée de cadeau. " \
                  "IMPORTANT : demander une confirmation explicite à l'utilisateur avant d'appeler cet outil."
      input_schema(
        properties: {
          id: { type: "integer", description: "ID de l'idée de cadeau (obtenu via search_gift_ideas)" }
        },
        required: %w[id]
      )
      output_schema(
        type: "object",
        properties: {
          message: { type: "string" },
          id:      { type: "integer" }
        },
        required: %w[message id]
      )

      class << self
        def call(server_context:, id:)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: id)

          return not_found_response(id) unless gift_idea
          return unauthorized_response(id) unless GiftIdeaPolicy.new(user, gift_idea).destroy?

          gift_idea.destroy!
          data = { message: "Idée de cadeau supprimée avec succès", id: id }
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data.transform_keys(&:to_s)
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def not_found_response(id)
          data = { "message" => "Idée de cadeau introuvable", "id" => id }
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            error: true,
            structured_content: data
          )
        end

        def unauthorized_response(id)
          data = { "message" => "Accès non autorisé", "id" => id }
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            error: true,
            structured_content: data
          )
        end
      end
    end
  end
end
