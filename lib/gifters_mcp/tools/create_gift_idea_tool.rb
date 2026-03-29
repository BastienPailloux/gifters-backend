# frozen_string_literal: true

module GiftersMcp
  module Tools
    class CreateGiftIdeaTool < MCP::Tool
      description "Crée une nouvelle idée de cadeau. " \
                  "Avant d'appeler cet outil, demander chaque paramètre manquant un par un (obligatoires d'abord, optionnels ensuite)."
      input_schema(
        properties: {
          title: {
            type: "string",
            description: "Titre de l'idée de cadeau"
          },
          recipient_ids: {
            type: "array",
            items: { type: "integer" },
            description: "IDs des utilisateurs destinataires (doivent partager un groupe avec le créateur)"
          },
          description: {
            type: "string",
            description: "Description détaillée (optionnel)"
          },
          price: {
            type: "number",
            description: "Prix indicatif en euros (optionnel)"
          },
          url: {
            type: "string",
            description: "Lien vers le produit (optionnel)"
          }
        },
        required: %w[title recipient_ids]
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
        def call(server_context:, title:, recipient_ids:, description: nil, price: nil, url: nil)
          user = user_from_context(server_context)
          recipients = User.where(id: Array(recipient_ids))

          gift_idea = GiftIdea.new(
            title:       title,
            description: description,
            price:       price,
            link:        url,
            created_by:  user,
            status:      'proposed'
          )
          gift_idea.recipients = recipients

          if gift_idea.save
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

        def error_content(message)
          { "id" => 0, "title" => message, "status" => "proposed", "url" => "" }
        end
      end
    end
  end
end
