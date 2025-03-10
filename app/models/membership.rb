class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  # Constants
  ROLES = %w[member admin].freeze

  # Validations
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :group_id, message: "est déjà membre de ce groupe" }

  # Callbacks
  before_validation :set_default_role

  # Methods
  def admin?
    role == 'admin'
  end

  def user_name
    user&.name
  end

  def user_email
    user&.email
  end

  private

  def set_default_role
    self.role ||= 'member'
  end
end
