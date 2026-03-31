# frozen_string_literal: true

module GiftersMcp
  module Serializers
    module GiftIdeaSerializer
      # Sérialise une idée de cadeau pour l'agent IA.
      # Si l'utilisateur courant est destinataire, le statut et l'acheteur sont masqués
      # pour ne pas gâcher la surprise.
      def self.serialize(gift_idea, current_user)
        recipient = gift_idea.is_recipient?(current_user)
        {
          id:              gift_idea.id,
          title:           gift_idea.title,
          status:          recipient ? "proposed" : gift_idea.status,
          link:            gift_idea.link,
          price:           gift_idea.price.nil? ? nil : gift_idea.price.to_f,
          description:     gift_idea.description,
          recipient_names: gift_idea.recipients.pluck(:name),
          created_by_name: gift_idea.created_by&.name,
          buyer_name:      recipient ? nil : gift_idea.buyer&.name
        }
      end

      # Version compacte pour les résultats de recherche (search tool)
      def self.serialize_compact(gift_idea, current_user)
        recipient = gift_idea.is_recipient?(current_user)
        {
          id:          gift_idea.id,
          title:       gift_idea.title,
          status:      recipient ? "proposed" : gift_idea.status,
          description: gift_idea.description,
          url:         "/gift-ideas/#{gift_idea.id}"
        }
      end
    end
  end
end
