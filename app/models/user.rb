class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Relations pour les comptes parent/enfant
  belongs_to :parent, class_name: 'User', optional: true
  has_many :children, class_name: 'User', foreign_key: 'parent_id', dependent: :destroy

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_gift_ideas, class_name: 'GiftIdea', foreign_key: 'created_by_id', dependent: :destroy
  has_many :created_invitations, class_name: 'Invitation', foreign_key: 'created_by_id', dependent: :destroy

  # Relations pour les destinataires de cadeaux
  has_many :gift_recipients, dependent: :destroy
  has_many :received_gift_ideas, through: :gift_recipients, source: :gift_idea

  # Scopes
  scope :standard, -> { where(account_type: 'standard') }
  scope :managed, -> { where(account_type: 'managed') }

  # Validations
  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: %w[standard managed] }
  validates :parent_id, presence: true, if: :managed?
  validates :parent_id, absence: true, if: :standard?
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :standard?
  validates :email, uniqueness: { allow_blank: true }, if: :managed?
  validates :password, presence: true, if: -> { standard? && password_required? }

  # Methods
  def common_groups_with(user)
    groups & user.groups
  end

  def has_common_group_with?(user)
    common_groups_with(user).any?
  end

  # Retourne les IDs des utilisateurs avec lesquels l'utilisateur partage un groupe
  def common_groups_with_users_ids
    # Retourner un tableau vide si l'utilisateur n'a pas de groupes
    group_ids = self.groups.pluck(:id)
    return [] if group_ids.empty?

    User.joins(:memberships)
        .where(memberships: { group_id: group_ids })
        .where.not(id: self.id)
        .distinct
        .pluck(:id)
  end

  # Méthode pour personnaliser les claims JWT
  def jwt_payload
    Rails.logger.info("User#jwt_payload - Générant payload pour utilisateur: #{id}, #{email}")

    payload = {
      user_id: id,
      email: email,
      name: name,
      jti: SecureRandom.uuid,
      exp: (Time.now + 24.hours).to_i
    }

    Rails.logger.info("User#jwt_payload - Payload généré: #{payload.inspect}")
    payload
  end

  # Méthodes pour la gestion de la newsletter
  def newsletter_subscription_changed?(new_status)
    # Conversion explicite en booléen pour garantir une comparaison cohérente
    converted_status = ActiveModel::Type::Boolean.new.cast(new_status)
    self.newsletter_subscription != converted_status
  end

  def update_brevo_subscription
    if self.newsletter_subscription
      # L'utilisateur s'est abonné
      response = BrevoService.subscribe_contact(self.email)
      unless response[:success]
        Rails.logger.error("User#update_brevo_subscription - Erreur lors de l'abonnement Brevo: #{response[:error]}")
      end
    else
      # L'utilisateur s'est désabonné
      response = BrevoService.unsubscribe_contact(self.email)
      unless response[:success]
        Rails.logger.error("User#update_brevo_subscription - Erreur lors du désabonnement Brevo: #{response[:error]}")
      end
    end
    response = { success: true } if response.nil?
    response
  end

  # Méthodes pour les comptes managed
  def managed?
    account_type == 'managed'
  end

  def standard?
    account_type == 'standard'
  end

  def has_children?
    children.any?
  end

  def can_access_as_parent?(user)
    # Un parent peut accéder aux données de ses enfants
    return false if user.nil?
    user.parent_id == self.id
  end

  # Override de la méthode Devise pour désactiver l'authentification des comptes managed
  def active_for_authentication?
    super && standard?
  end

  def inactive_message
    managed? ? :account_managed : super
  end

  private

  # Override des méthodes Devise pour désactiver les validations email/password pour les comptes managed
  def email_required?
    standard?
  end

  def email_changed?
    super && standard?
  end

  def will_save_change_to_email?
    super && standard?
  end

  def password_required?
    return false if managed?
    return false if persisted? && password.blank? && password_confirmation.blank?
    true
  end
end
