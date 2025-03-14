class GiftIdeaSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :price, :link, :status, :image_url,
            :created_at, :updated_at, :created_by_id, :buyer_id

  # Ajouter les attributs au format camelCase pour le frontend
  attribute :recipients
  attribute :groupName
  attribute :buyerId
  attribute :buyerName
  attribute :buyer_data

  # Les associations pour les relations
  belongs_to :created_by, serializer: UserSerializer
  belongs_to :buyer, serializer: UserSerializer, optional: true

  # Définir les attributs camelCase pour l'intégration frontend
  def recipients
    object.recipients.map do |recipient|
      {
        id: recipient.id,
        name: recipient.name
      }
    end
  end

  def groupName
    # Trouver les groupes communs entre le créateur et les destinataires
    recipient_ids = object.recipients.pluck(:id)
    return "Aucun groupe commun" if recipient_ids.blank?

    # Trouver le premier groupe commun entre le créateur et au moins un destinataire
    common_groups = Membership.where(user_id: recipient_ids)
                               .joins("INNER JOIN memberships AS creator_memberships ON memberships.group_id = creator_memberships.group_id")
                               .where("creator_memberships.user_id = ?", object.created_by_id)
                               .select("DISTINCT memberships.group_id")
                               .limit(1)

    return "Aucun groupe commun" if common_groups.blank?

    Group.find(common_groups.first.group_id)&.name || "Aucun groupe commun"
  end

  def buyerId
    object.buyer_id
  end

  def buyerName
    object.buyer&.name
  end

  def buyer_data
    return nil if object.buyer.nil?
    {
      id: object.buyer.id,
      name: object.buyer.name
    }
  end

  # Ces méthodes sont gardées pour compatibilité mais ne sont plus utilisées dans le frontend
  def for_user_name
    object.recipients.first&.name || "Aucun destinataire"
  end

  def created_by_name
    object.created_by&.name
  end
end
