# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # Scope pour filtrer les utilisateurs accessibles
  class Scope < Scope
    def resolve
      # L'utilisateur peut voir les utilisateurs avec qui il partage un groupe
      user_ids = user.common_groups_with_users_ids
      scope.where(id: [user.id] + user_ids)
    end
  end

  def index?
    true
  end

  def show?
    # Peut voir un utilisateur si on partage un groupe avec lui ou si c'est soi-même
    return true if record.id == user.id
    return true if user.has_common_group_with?(record)

    # OU si un de ses enfants partage un groupe avec l'utilisateur à voir (1 requête optimisée)
    Membership.joins("INNER JOIN memberships AS child_memberships ON memberships.group_id = child_memberships.group_id")
      .where(memberships: { user_id: record.id })
      .where(child_memberships: { user_id: User.where(parent_id: user.id).select(:id) })
      .exists?
  end

  def shared_users?
    true
  end

  def update?
    # Seulement son propre profil
    record.id == user.id
  end

  def destroy?
    # Seulement son propre profil
    record.id == user.id
  end

  def update_locale?
    # Seulement sa propre locale
    record.id == user.id
  end

  # Méthodes pour la gestion des comptes enfants
  def manage_as_child?
    # Peut gérer un compte si on est le parent
    user.can_access_as_parent?(record)
  end

  alias_method :show_child?, :manage_as_child?
  alias_method :update_child?, :manage_as_child?
  alias_method :destroy_child?, :manage_as_child?

  def create_child?
    # Tout utilisateur authentifié peut créer un compte enfant
    true
  end

  def index_children?
    # Tout utilisateur authentifié peut voir ses propres enfants
    true
  end
end
