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
    member? || user.children.any? { |child| record.users.include?(child) }
  end

  def create?
    true
  end

  def update?
    admin? || user.children.any? { |child| record.admin_users.include?(child) }
  end

  def destroy?
    admin? || user.children.any? { |child| record.admin_users.include?(child) }
  end

  def leave?
    return true unless record.admin_users.size == 1 && record.admin_users.include?(user)
    false
  end

  def manage_invitations?
    admin?
  end

  private

  def member?
    record.users.include?(user)
  end

  def admin?
    record.admin_users.include?(user)
  end
end
