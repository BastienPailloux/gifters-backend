# frozen_string_literal: true

module Tools
  module GiftIdeas
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
        def authorize!(user, params)
          gift_idea = GiftIdea.find_by(id: params[:id])
          return false unless gift_idea
          GiftIdeaPolicy.new(user, gift_idea).destroy?
        end

        def call(server_context:, id:)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: id)

          return not_found_response(id) unless gift_idea

          gift_idea.destroy!
          data = { message: "Deleted", id: id }
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
      end
    end
  end
end
