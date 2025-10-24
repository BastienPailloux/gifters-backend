# frozen_string_literal: true

class GiftIdeaPolicy < ApplicationPolicy
  # Scope pour filtrer les gift ideas visibles par l'utilisateur
  class Scope < Scope
    def resolve
      # Gift ideas visibles par l'utilisateur (logique existante du modèle)
      visible_by_user = scope.visible_to_user(user)

      # Gift ideas créées par les enfants de l'utilisateur
      created_by_children = scope.where(
        created_by_id: User.where(parent_id: user.id).select(:id)
      )

      # Gift ideas dont un enfant est destinataire
      for_children = scope.where(
        id: GiftRecipient
          .where(user_id: User.where(parent_id: user.id).select(:id))
          .select(:gift_idea_id)
      )

      # Combiner les 3 ensembles avec UNION pour éviter les doublons
      scope.from("(
        (#{visible_by_user.to_sql})
        UNION
        (#{created_by_children.to_sql})
        UNION
        (#{for_children.to_sql})
      ) AS gift_ideas")
    end
  end

  def index?
    true # Tout utilisateur authentifié peut lister les gift ideas
  end

  def show?
    return true if record.visible_to?(user)

    # OU si c'est une gift idea créée par un enfant
    return true if User.exists?(id: record.created_by_id, parent_id: user.id)

    # OU si c'est une gift idea pour un enfant
    GiftRecipient.joins(:user)
      .where(gift_idea_id: record.id)
      .where(users: { parent_id: user.id })
      .exists?
  end

  def create?
    true # Tout utilisateur authentifié peut créer une gift idea
  end

  def update?
    # Seul le créateur peut modifier
    return true if record.created_by_id == user.id

    # OU si c'est créé par un enfant
    User.exists?(id: record.created_by_id, parent_id: user.id)
  end

  def destroy?
    # Seul le créateur peut supprimer
    return true if record.created_by_id == user.id

    # OU si c'est créé par un enfant
    User.exists?(id: record.created_by_id, parent_id: user.id)
  end

  def mark_as_buying?
    # Un utilisateur peut marquer comme "en cours d'achat" si :
    # - Il n'est pas destinataire (ni lui ni ses enfants)
    # - Le cadeau est visible pour lui
    # - Le cadeau n'est pas déjà acheté
    return false if record.is_recipient?(user)
    return false if GiftRecipient.joins(:user).where(gift_idea_id: record.id, users: { parent_id: user.id }).exists?
    return false if record.status == 'bought'

    # Visible pour lui ou pour un de ses enfants
    record.visible_to?(user) || show?
  end

  def mark_as_bought?
    # Un utilisateur peut marquer comme "acheté" si :
    # - Il est l'acheteur (buyer) ou le créateur
    # - OU si c'est créé par un enfant
    # - Le cadeau n'est pas déjà acheté
    return false if record.status == 'bought'
    return true if record.buyer_id == user.id
    return true if record.created_by_id == user.id

    # OU si c'est créé par un enfant (1 requête)
    User.exists?(id: record.created_by_id, parent_id: user.id)
  end

  def cancel_buying?
    # Un utilisateur peut annuler l'achat si :
    # - Il est l'acheteur
    # - Le statut est "buying"
    record.buyer_id == user.id && record.status == 'buying'
  end

  # Méthode helper pour vérifier si un créateur peut créer pour un destinataire
  def self.can_create_for_recipient?(creator, recipient)
    # Autorisé si c'est soi-même
    return true if creator.id == recipient.id

    # Autorisé si on partage un groupe
    return true if creator.has_common_group_with?(recipient)

    # Autorisé si le créateur est le parent du destinataire
    return true if creator.can_access_as_parent?(recipient)

    # Autorisé si le destinataire est le parent du créateur (enfant crée pour parent)
    return true if recipient.can_access_as_parent?(creator)

    false
  end
end
