class GiftIdeaSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :price, :link, :status, :image_url,
            :created_at, :updated_at, :created_by_id, :buyer_id

  # Attributs standardisés et simplifiés
  attribute :recipients
  attribute :group_name

  # Permissions calculées pour le frontend
  attribute :can_mark_as_buying
  attribute :can_mark_as_bought
  attribute :can_cancel_buying

  # Associations
  belongs_to :created_by, serializer: UserSerializer
  belongs_to :buyer, serializer: UserSerializer, optional: true

  # Définir l'attribut recipients pour retourner une liste simplifiée
  def recipients
    object.recipients.map do |recipient|
      {
        id: recipient.id,
        name: recipient.name
      }
    end
  end

  # Trouver le groupe commun (renommé de groupName à group_name pour cohérence)
  def group_name
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

  # Permissions calculées basées sur les policies
  def can_mark_as_buying
    return false unless current_user
    GiftIdeaPolicy.new(current_user, object).mark_as_buying?
  end

  def can_mark_as_bought
    return false unless current_user
    GiftIdeaPolicy.new(current_user, object).mark_as_bought?
  end

  def can_cancel_buying
    return false unless current_user
    GiftIdeaPolicy.new(current_user, object).cancel_buying?
  end

  # Ces méthodes sont gardées pour compatibilité mais ne sont plus utilisées dans le frontend
  def for_user_name
    object.recipients.first&.name || "Aucun destinataire"
  end

  def created_by_name
    object.created_by&.name
  end

  private

  def current_user
    scope
  end
end
