# frozen_string_literal: true

module GiftersMcp
  module Tools
    class MarkAsBuyingTool < MCP::Tool
      description "Marque une idée de cadeau comme 'en cours d'achat'. " \
                  "IMPORTANT : demander une confirmation explicite à l'utilisateur avant d'appeler cet outil. " \
                  "Si l'utilisateur a des enfants (comptes gérés), demander au nom de qui il achète (actor_id)."
      input_schema(
        properties: {
          id:       { type: "integer", description: "ID de l'idée de cadeau (obtenu via search_gift_ideas)" },
          actor_id: { type: "integer", description: "ID de l'acheteur : current_user ou un de ses enfants (optionnel, défaut = current_user)" }
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
        def call(server_context:, id:, actor_id: nil)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: id)

          return not_found_response unless gift_idea
          return unauthorized_response unless GiftIdeaPolicy.new(user, gift_idea).mark_as_buying?

          buyer = resolve_buyer(user, actor_id)
          return unauthorized_response unless buyer

          gift_idea.mark_as_buying(buyer)
          data = serialize(gift_idea)
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data.transform_keys(&:to_s)
          )
        rescue StandardError => e
          MCP::Tool::Response.new([{ type: "text", text: { error: e.message }.to_json }])
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def resolve_buyer(user, actor_id)
          return user if actor_id.nil?

          actor = User.find_by(id: actor_id)
          return nil unless actor
          return actor if actor.id == user.id
          return actor if user.can_access_as_parent?(actor)

          nil
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
