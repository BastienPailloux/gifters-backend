# frozen_string_literal: true

class GiftIdeaPolicy < ApplicationPolicy
  # Scope pour filtrer les gift ideas visibles par l'utilisateur
  class Scope < Scope
    def resolve
      # Collecter tous les IDs de gift ideas visibles avec des pluck
      # pour éviter les problèmes avec les scopes Ruby (.map, .select)
      # Cette approche fait un nombre FIXE de requêtes (5 max), pas du N+1
      gift_idea_ids = Set.new

      # 1. Gift ideas visibles par l'utilisateur (scope du modèle) - 1 requête
      gift_idea_ids.merge(scope.visible_to_user(user).pluck(:id))

      # 2. Gift ideas créées par les enfants de l'utilisateur - 2 requêtes
      children_ids = User.where(parent_id: user.id).pluck(:id)
      if children_ids.any?
        gift_idea_ids.merge(scope.where(created_by_id: children_ids).pluck(:id))
      end

      # 3. Gift ideas dont un enfant est destinataire - 1 requête
      if children_ids.any?
        gift_idea_ids.merge(
          GiftRecipient.where(user_id: children_ids).pluck(:gift_idea_id)
        )
      end

      # 4. Retourner une relation ActiveRecord avec tous les IDs - 1 requête finale
      gift_idea_ids.empty? ? scope.none : scope.where(id: gift_idea_ids.to_a)
    end
  end

  def index?
    true # Tout utilisateur authentifié peut lister les gift ideas
  end

  def show?
    return true if record.visible_to?(user)

    # OU si c'est une gift idea créée par un enfant
    return true if owned_by_user_or_children?(record)

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
    owned_by_user_or_children?(record)
  end

  def destroy?
    owned_by_user_or_children?(record)
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
    # - Il est l'acheteur (buyer) ou le créateur/parent du créateur
    # - Le cadeau n'est pas déjà acheté
    return false if record.status == 'bought'
    return true if record.buyer_id == user.id

    owned_by_user_or_children?(record)
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
