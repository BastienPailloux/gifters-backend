class GiftIdeaSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :price, :link, :status, :image_url,
            :created_at, :updated_at, :for_user_id, :created_by_id

  # Ajouter les associations
  belongs_to :for_user, serializer: UserSerializer
  belongs_to :created_by, serializer: UserSerializer

  # Ajouter les attributs pour les noms, utiles pour les listes et les recherches rapides
  attribute :for_user_name
  attribute :created_by_name
  attribute :group_name

  # Utiliser les relations pour récupérer les noms
  def for_user_name
    object.for_user.name
  end

  def created_by_name
    object.created_by.name
  end

  # Déterminer le groupe commun entre for_user et created_by
  def group_name
    # Trouver le groupe commun (s'il y en a plusieurs, prend le premier)
    common_groups = object.for_user.common_groups_with(object.created_by)
    return "Aucun groupe commun" if common_groups.empty?

    # Trier par nom pour avoir une réponse cohérente
    common_groups.sort_by(&:name).first.name
  end
end
