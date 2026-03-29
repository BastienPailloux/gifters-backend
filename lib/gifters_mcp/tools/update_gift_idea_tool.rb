# frozen_string_literal: true

module GiftersMcp
  module Tools
    class UpdateGiftIdeaTool < MCP::Tool
      description "Met à jour une idée de cadeau. Utiliser search_gift_ideas d'abord pour trouver l'ID. " \
                  "Demander chaque champ à modifier un par un."
      input_schema(
        properties: {
          id:          { type: "integer", description: "ID de l'idée de cadeau (obtenu via search_gift_ideas)" },
          title:       { type: "string",  description: "Nouveau titre (optionnel)" },
          description: { type: "string",  description: "Nouvelle description (optionnel)" },
          price:       { type: "number",  description: "Nouveau prix en euros (optionnel)" },
          url:         { type: "string",  description: "Nouveau lien produit (optionnel)" }
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
        def call(server_context:, id:, title: nil, description: nil, price: nil, url: nil)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: id)

          return not_found_response unless gift_idea
          return unauthorized_response unless GiftIdeaPolicy.new(user, gift_idea).update?

          attrs = {}
          attrs[:title]       = title       if title
          attrs[:description] = description if description
          attrs[:price]       = price       if price
          attrs[:link]        = url         if url

          if attrs.empty? || gift_idea.update(attrs)
            data = serialize(gift_idea)
            MCP::Tool::Response.new(
              [{ type: "text", text: data.to_json }],
              structured_content: data.transform_keys(&:to_s)
            )
          else
            message = gift_idea.errors.full_messages.join(', ')
            MCP::Tool::Response.new(
              [{ type: "text", text: { error: message }.to_json }],
              error: true,
              structured_content: error_content(message)
            )
          end
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
            structured_content: error_content("Idée de cadeau introuvable")
          )
        end

        def unauthorized_response
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: "Accès non autorisé" }.to_json }],
            error: true,
            structured_content: error_content("Accès non autorisé")
          )
        end

        def error_content(message)
          { "id" => 0, "title" => message, "status" => "proposed", "url" => "" }
        end
      end
    end
  end
end
