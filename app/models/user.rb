class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_gift_ideas, class_name: 'GiftIdea', foreign_key: 'created_by_id', dependent: :destroy
  has_many :received_gift_ideas, class_name: 'GiftIdea', foreign_key: 'for_user_id', dependent: :destroy
  has_many :created_invitations, class_name: 'Invitation', foreign_key: 'created_by_id', dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Methods
  def common_groups_with(user)
    groups & user.groups
  end

  def has_common_group_with?(user)
    common_groups_with(user).any?
  end

  # Retourne les IDs des utilisateurs avec lesquels l'utilisateur partage un groupe
  def common_groups_with_users_ids
    User.joins(:memberships)
        .where(memberships: { group_id: self.groups.pluck(:id) })
        .where.not(id: self.id)
        .distinct
        .pluck(:id)
  end

  # Méthode pour personnaliser les claims JWT
  def jwt_payload
    {
      user_id: id,
      name: name,
      email: email
    }
  end
end
