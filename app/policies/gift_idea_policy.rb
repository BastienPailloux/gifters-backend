# frozen_string_literal: true

class GiftIdeaPolicy < ApplicationPolicy
  # Scope pour filtrer les gift ideas visibles par l'utilisateur
  class Scope < Scope
    def resolve
      # Collecter tous les IDs de gift ideas visibles
      gift_idea_ids = Set.new

      # 1. Gift ideas visibles par l'utilisateur (scope du modèle)
      gift_idea_ids.merge(scope.visible_to_user(user).pluck(:id))

      # 2. Gift ideas créées par les enfants de l'utilisateur
      children_ids = User.where(parent_id: user.id).pluck(:id)
      if children_ids.any?
        gift_idea_ids.merge(scope.where(created_by_id: children_ids).pluck(:id))
      end

      # 3. Gift ideas dont un enfant est destinataire
      if children_ids.any?
        gift_idea_ids.merge(
          GiftRecipient.where(user_id: children_ids).pluck(:gift_idea_id)
        )
      end

      # 4. Retourner une relation ActiveRecord avec tous les IDs
      gift_idea_ids.empty? ? scope.none : scope.where(id: gift_idea_ids.to_a)
    end
  end

  def index?
    true # Tout utilisateur authentifié peut lister les gift ideas
  end

  def show?
    return true if record.visible_to?(user)

    # Si c'est une gift idea créée par un enfant
    return true if owned_by_user_or_children?(record)

    # Si c'est une gift idea pour un enfant
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
    # - Il n'est pas lui-même destinataire (mais peut acheter pour ses enfants)
    # - Le cadeau est visible pour lui ou pour un de ses enfants
    # - Le cadeau n'est pas déjà en cours d'achat ou acheté
    return false if record.is_recipient?(user)
    return false if record.status == 'buying'
    return false if record.status == 'bought'

    # Visible pour lui directement
    return true if record.visible_to?(user)

    # Visible via show? (créé par lui/enfant ou enfant destinataire - déjà exclu ci-dessus)
    return true if owned_by_user_or_children?(record)

    # Visible pour un de ses enfants (enfant partage un groupe avec un destinataire)
    if user.has_children?
      user.children.each do |child|
        # Vérifier que l'enfant n'est pas destinataire
        next if record.is_recipient?(child)
        # Vérifier que l'enfant partage un groupe avec au moins un destinataire
        record.recipients.each do |recipient|
          return true if child.has_common_group_with?(recipient)
        end
      end
    end

    false
  end

  def mark_as_bought?
    # Un utilisateur peut marquer comme "acheté" si :
    # - Il est l'acheteur (buyer) ou un de ses enfants est l'acheteur
    # - Ou le créateur/parent du créateur
    # - Le cadeau n'est pas déjà acheté
    return false if record.status == 'bought'
    return true if record.buyer_id == user.id

    # Si un enfant est l'acheteur, le parent peut aussi marquer comme acheté
    return true if record.buyer_id.present? && User.exists?(id: record.buyer_id, parent_id: user.id)

    owned_by_user_or_children?(record)
  end

  def cancel_buying?
    # Un utilisateur peut annuler l'achat si :
    # - Il est l'acheteur ou un de ses enfants est l'acheteur
    # - Le statut est "buying"
    return false unless record.status == 'buying'
    return true if record.buyer_id == user.id

    # Si un enfant est l'acheteur, le parent peut aussi annuler
    User.exists?(id: record.buyer_id, parent_id: user.id)
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
