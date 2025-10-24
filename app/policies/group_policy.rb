# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  # Scope pour filtrer les groupes accessibles par l'utilisateur
  class Scope < Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end

  def index?
    true
  end

  def show?
    member_or_child_member_of?(record)
  end

  def create?
    true
  end

  def update?
    admin_or_child_admin_of?(record)
  end

  def destroy?
    admin_or_child_admin_of?(record)
  end

  def leave?
    # L'utilisateur doit être membre du groupe pour le quitter
    return false unless member_or_child_member_of?(record)

    # Un utilisateur ne peut pas quitter s'il est le dernier admin
    return false if record.admin_users.size == 1 && record.admin_users.include?(user)

    true
  end

  def manage_invitations?
    admin_or_child_admin_of?(record)
  end

  def manage_memberships?
    admin_or_child_admin_of?(record)
  end

  def show_memberships?
    member_or_child_member_of?(record)
  end

  private

  def member?
    record.users.include?(user)
  end

  def admin?
    record.admin_users.include?(user)
  end
end
