class Group < ApplicationRecord
  # Relations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  # Validations
  validates :name, presence: true
  validates :invite_code, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_invite_code, on: :create

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

  private

  def generate_invite_code
    self.invite_code ||= SecureRandom.alphanumeric(8).upcase
  end
end
