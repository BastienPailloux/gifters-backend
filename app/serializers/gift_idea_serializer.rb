class GiftIdeaSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :price, :link, :status, :image_url,
            :created_at, :updated_at, :for_user_id, :created_by_id

  # Ajouter les attributs au format camelCase pour le frontend
  attribute :forUser
  attribute :forUserName
  attribute :groupName

  # Les anciennes associations pour compatibilité
  belongs_to :for_user, serializer: UserSerializer
  belongs_to :created_by, serializer: UserSerializer

  # Définir les attributs camelCase pour l'intégration frontend
  def forUser
    return nil if object.for_user.nil?
    {
      id: object.for_user.id,
      name: object.for_user.name
    }
  end

  def forUserName
    object.for_user&.name
  end

  def groupName
    # Trouver le groupe commun (s'il y en a plusieurs, prend le premier)
    common_groups = object.for_user&.common_groups_with(object.created_by)
    return "Aucun groupe commun" if common_groups.blank?

    # Trier par nom pour avoir une réponse cohérente
    common_groups.sort_by(&:name).first.name
  end

  # Ces méthodes sont gardées pour compatibilité mais ne sont plus utilisées dans le frontend
  def for_user_name
    object.for_user&.name
  end

  def created_by_name
    object.created_by&.name
  end
end
