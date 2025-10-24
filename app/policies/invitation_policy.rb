# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  # Scope pour filtrer les invitations accessibles par l'utilisateur
  class Scope < Scope
    def resolve
      # L'utilisateur peut voir les invitations des groupes dont il est membre
      scope.joins(:group).where(groups: { id: user.groups.pluck(:id) })
    end
  end

  def index?
    true
  end

  def show?
    # Peut voir une invitation si on fait partie du groupe
    user.groups.include?(record.group)
  end

  def create?
    # Seul un membre du groupe peut créer une invitation
    record.group.users.include?(user)
  end

  def destroy?
    # Seul un admin du groupe peut supprimer une invitation
    record.group.admin_users.include?(user)
  end

  def send_email?
    # Seul un admin du groupe peut envoyer un email d'invitation
    record.group.admin_users.include?(user)
  end

  def accept?
    # Tout utilisateur authentifié peut accepter une invitation (pas besoin d'être membre)
    true
  end
end
