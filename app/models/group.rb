class Group < ApplicationRecord
  # Relations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  # Validations
  validates :name, presence: true

  # Methods
  def add_user(user, role = 'member')
    memberships.create(user: user, role: role)
  end

  def admin_users
    memberships.where(role: 'admin').map(&:user)
  end
end
