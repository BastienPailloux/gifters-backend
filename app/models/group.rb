class Group < ApplicationRecord
  # Relations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Callbacks

  # Methods
  def add_user(user, role = 'member')
    memberships.create(user: user, role: role)
  end

  def admin_users
    memberships.where(role: 'admin').map(&:user)
  end

  def admin_count
    memberships.where(role: 'admin').count
  end

  def create_invitation(created_by, role = 'member')
    invitations.create(created_by: created_by, role: role)
  end
end
