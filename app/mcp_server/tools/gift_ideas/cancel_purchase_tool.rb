# frozen_string_literal: true

module Tools
  module GiftIdeas
    class CancelPurchaseTool < MCP::Tool
      description "Annule un achat (en cours ou déjà acheté) et remet l'idée de cadeau en 'proposé'. " \
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
          id:     { type: "integer" },
          title:  { type: "string" },
          status: { type: "string" },
          url:    { type: "string" }
        },
        required: %w[id title status url]
      )

      class << self
        def authorize!(user, params)
          gift_idea = GiftIdea.find_by(id: params[:id])
          return false unless gift_idea
          GiftIdeaPolicy.new(user, gift_idea).cancel_purchase?
        end

        def call(server_context:, id:)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: id)

          return not_found_response unless gift_idea

          gift_idea.cancel_purchase
          data = serialize(gift_idea)
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data.transform_keys(&:to_s)
          )
        rescue StandardError => e
          MCP::Tool::Response.new([{ type: "text", text: { error: e.message }.to_json }], error: true)
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def serialize(g)
          { id: g.id, title: g.title, status: g.status, url: "/gift-ideas/#{g.id}" }
        end

        def not_found_response
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: "Idée de cadeau introuvable" }.to_json }],
            error: true,
            structured_content: { "id" => 0, "title" => "Introuvable", "status" => "proposed", "url" => "" }
          )
        end

        def unauthorized_response
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: "Action non autorisée" }.to_json }],
            error: true,
            structured_content: { "id" => 0, "title" => "Non autorisé", "status" => "proposed", "url" => "" }
          )
        end
      end
    end
  end
end
