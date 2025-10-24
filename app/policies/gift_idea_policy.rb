# frozen_string_literal: true

class GiftIdeaPolicy < ApplicationPolicy
  # Scope pour filtrer les gift ideas visibles par l'utilisateur
  class Scope < Scope
    def resolve
      scope.visible_to_user(user)
    end
  end

  def index?
    true # Tout utilisateur authentifié peut lister les gift ideas
  end

  def show?
    record.visible_to?(user)
  end

  def create?
    true # Tout utilisateur authentifié peut créer une gift idea
  end

  def update?
    # Seul le créateur peut modifier
    record.created_by_id == user.id
  end

  def destroy?
    # Seul le créateur peut supprimer
    record.created_by_id == user.id
  end

  def mark_as_buying?
    # Un utilisateur peut marquer comme "en cours d'achat" si :
    # - Il n'est pas le créateur
    # - Il n'est pas destinataire
    # - Le cadeau est visible pour lui
    # - Le cadeau n'est pas déjà acheté
    return false if record.created_by_id == user.id
    return false if record.is_recipient?(user)
    return false if record.status == 'bought'
    record.visible_to?(user)
  end

  def mark_as_bought?
    # Un utilisateur peut marquer comme "acheté" si :
    # - Il est l'acheteur (buyer) ou le créateur
    # - Le cadeau n'est pas déjà acheté
    return false if record.status == 'bought'
    record.buyer_id == user.id || record.created_by_id == user.id
  end

  def cancel_buying?
    # Un utilisateur peut annuler l'achat si :
    # - Il est l'acheteur
    # - Le statut est "buying"
    record.buyer_id == user.id && record.status == 'buying'
  end
end
