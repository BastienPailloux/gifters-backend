# frozen_string_literal: true

module Tools
  module GiftIdeas
    class GetGiftIdeaTool < MCP::Tool
      description "Récupère le détail d'une idée de cadeau par son ID (si l'utilisateur y a accès)."
      input_schema(
        properties: {
          gift_idea_id: {
            type: "integer",
            description: "ID de l'idée de cadeau"
          }
        },
        required: ["gift_idea_id"]
      )
      output_schema(
        properties: {
          id: { type: "integer" },
          title: { type: "string" },
          status: { type: "string", enum: %w[proposed buying bought] },
          link: { type: ["string", "null"] },
          gifters_url: { type: "string" },
          price: { type: ["number", "null"] },
          description: { type: ["string", "null"] },
          recipient_names: { type: "array", items: { type: "string" } },
          created_by_name: { type: ["string", "null"] },
          buyer_name: { type: ["string", "null"] },
          created_at: { type: "string", format: "date-time" },
          updated_at: { type: "string", format: "date-time" }
        },
        required: %w[id title status gifters_url created_at updated_at]
      )

      class << self
        def authorize!(user, params)
          gift_idea = GiftIdea.find_by(id: params[:gift_idea_id])
          return false unless gift_idea
          GiftIdeaPolicy.new(user, gift_idea).show?
        end

        def call(server_context:, gift_idea_id:)
          user = user_from_context(server_context)
          gift_idea = GiftIdea.find_by(id: gift_idea_id)
          unless gift_idea
            return MCP::Tool::Response.new(
              [{ type: "text", text: { error: "Idée de cadeau introuvable" }.to_json }],
              error: true,
              structured_content: error_structured_content("Idée de cadeau introuvable")
            )
          end
          data = Serializers::GiftIdeaSerializer.serialize(gift_idea, user).merge(
            created_at: gift_idea.created_at.iso8601,
            updated_at: gift_idea.updated_at.iso8601
          )
          data_str = data.transform_keys(&:to_s)
          # structured_content requis par le client MCP quand l'outil a un output_schema
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data_str
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end


        # Contenu structuré minimal pour les erreurs (le client MCP exige structured_content si output_schema est défini)
        def error_structured_content(message)
          now = Time.current.iso8601
          {
            "id" => 0,
            "title" => message,
            "status" => "proposed",
            "link" => nil,
            "gifters_url" => "/gift-ideas/0",
            "price" => nil,
            "description" => nil,
            "recipient_names" => [],
            "created_by_name" => nil,
            "buyer_name" => nil,
            "created_at" => now,
            "updated_at" => now
          }
        end
      end
    end
  end
end
