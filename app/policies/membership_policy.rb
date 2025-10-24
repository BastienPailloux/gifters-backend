# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  # Scope pour filtrer les memberships accessibles par l'utilisateur
  class Scope < Scope
    def resolve
      # L'utilisateur peut voir les memberships des groupes dont il est membre
      scope.joins(:group).where(groups: { id: user.groups.pluck(:id) })
    end
  end

  def index?
    true
  end

  def show?
    # Peut voir un membership si on fait partie du même groupe
    user.groups.include?(record.group)
  end

  def create?
    # Seul un admin du groupe peut créer un membership
    record.group.admin_users.include?(user)
  end

  def update?
    # Seul un admin du groupe peut modifier un membership (changer le rôle)
    record.group.admin_users.include?(user)
  end

  def destroy?
    # Un admin peut supprimer un membre
    # OU un membre peut se supprimer lui-même (quitter le groupe)
    return true if record.group.admin_users.include?(user)
    return true if record.user_id == user.id
    false
  end
end
