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
    member?
  end

  def create?
    true
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def leave?
    return true unless record.admin_users.size == 1 && record.admin_users.include?(user)
    false
  end

  private

  def member?
    record.users.include?(user)
  end

  def admin?
    record.admin_users.include?(user)
  end
end
