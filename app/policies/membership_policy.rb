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
    # Peut voir un membership si on fait partie du même groupe
    return true if user.groups.include?(record.group)

    # OU si un de ses enfants fait partie du groupe (une seule requête)
    Membership.exists?(user_id: User.where(parent_id: user.id).select(:id), group_id: record.group_id)
  end

  def create?
    # Seul un admin du groupe peut créer un membership
    return true if record.group.admin_users.include?(user)

    # OU si un de ses enfants est admin du groupe (une seule requête)
    Membership.exists?(
      user_id: User.where(parent_id: user.id).select(:id),
      group_id: record.group_id,
      role: 'admin'
    )
  end

  def update?
    # Seul un admin du groupe peut modifier un membership (changer le rôle)
    return true if record.group.admin_users.include?(user)

    # OU si un de ses enfants est admin du groupe (une seule requête)
    Membership.exists?(
      user_id: User.where(parent_id: user.id).select(:id),
      group_id: record.group_id,
      role: 'admin'
    )
  end

  def destroy?
    # Un admin peut supprimer un membre
    return true if record.group.admin_users.include?(user)

    # OU si un de ses enfants est admin du groupe
    return true if Membership.exists?(
      user_id: User.where(parent_id: user.id).select(:id),
      group_id: record.group_id,
      role: 'admin'
    )

    # OU un membre peut se supprimer lui-même (quitter le groupe)
    return true if record.user_id == user.id

    # OU si c'est le membership d'un de ses enfants
    User.exists?(id: record.user_id, parent_id: user.id)
  end
end
