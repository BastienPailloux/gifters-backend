# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  # Scope pour filtrer les invitations accessibles par l'utilisateur
  class Scope < Scope
    def resolve
      # L'utilisateur peut voir les invitations des groupes dont il est membre
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
    # Tout utilisateur authentifié peut voir une invitation
    # (nécessaire pour afficher les détails avant d'accepter)
    true
  end

  def create?
    # Seul un membre du groupe peut créer une invitation
    # OU si un de ses enfants est membre du groupe
    member_or_child_member_of?(record.group)
  end

  def destroy?
    # Seul un admin du groupe peut supprimer une invitation
    # OU si un de ses enfants est admin du groupe
    return true if admin_or_child_admin_of?(record.group)

    # OU le créateur de l'invitation (ou si c'est créé par un enfant)
    owned_by_user_or_children?(record, owner_field: :created_by_id)
  end

  def send_email?
    # Seul un admin du groupe peut envoyer un email d'invitation
    # OU si un de ses enfants est admin du groupe
    admin_or_child_admin_of?(record.group)
  end

  def accept?
    # Tout utilisateur authentifié peut accepter une invitation (pas besoin d'être membre)
    true
  end
end
