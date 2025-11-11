module Childrenable
  extend ActiveSupport::Concern

  included do
    # Relations parent/enfant auto-référencées
    belongs_to :parent, class_name: name, optional: true
    has_many :children, class_name: name, foreign_key: 'parent_id', dependent: :destroy

    # Scopes
    scope :standard, -> { where(account_type: 'standard') }
    scope :managed, -> { where(account_type: 'managed') }
  end

  # Méthodes d'instance
  def has_children?
    children.any?
  end

  def can_access_as_parent?(record)
    return false if record.nil?
    record.parent_id == self.id
  end

  def responsible_user
    if account_type == 'managed' && parent.present?
      parent
    else
      self
    end
  end
end
