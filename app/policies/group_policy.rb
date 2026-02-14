# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  # Scope pour filtrer les groupes accessibles par l'utilisateur (incluant les groupes des enfants)
  class Scope < Scope
    def resolve
      # Groupes de l'utilisateur
      user_group_ids = scope.joins(:memberships).where(memberships: { user_id: user.id }).pluck(:id)
      
      # Groupes des enfants
      children_ids = User.where(parent_id: user.id).pluck(:id)
      children_group_ids = children_ids.any? ? scope.joins(:memberships).where(memberships: { user_id: children_ids }).pluck(:id) : []
      
      # Union des deux
      all_group_ids = (user_group_ids + children_group_ids).uniq
      scope.where(id: all_group_ids)
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
    return false unless member_or_child_member_of?(record)

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
