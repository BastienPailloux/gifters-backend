# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  # Scope pour filtrer les memberships accessibles par l'utilisateur
  class Scope < Scope
    def resolve
      # L'utilisateur peut voir les memberships des groupes dont il est membre
      # OU des groupes dont un de ses enfants est membre

      # Récupérer les IDs des groupes de l'utilisateur
      user_group_ids = Membership.where(user_id: user.id).pluck(:group_id)

      # Récupérer les IDs des groupes des enfants en une seule requête
      children_group_ids = Membership
        .joins("INNER JOIN users ON users.id = memberships.user_id")
        .where(users: { parent_id: user.id })
        .pluck(:group_id)

      group_ids = (user_group_ids + children_group_ids).uniq

      scope.joins(:group).where(groups: { id: group_ids })
    end
  end

  def index?
    true
  end

  def show?
    member_or_child_member_of?(record.group)
  end

  def create?
    admin_or_child_admin_of?(record.group)
  end

  def update?
    admin_or_child_admin_of?(record.group)
  end

  def destroy?
    # Un admin peut supprimer un membre
    return true if admin_or_child_admin_of?(record.group)

    # OU un membre peut se supprimer lui-même (quitter le groupe)
    return true if record.user_id == user.id

    # OU si c'est le membership d'un de ses enfants
    owned_by_user_or_children?(record, owner_field: :user_id)
  end
end
