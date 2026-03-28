# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def index?   = user.present?
  def create?  = user.present?
  def show?    = record.user == user
  def update?  = record.user == user
  def stream?  = record.user == user
end
