class User < ApplicationRecord
  include Childrenable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_gift_ideas, class_name: 'GiftIdea', foreign_key: 'created_by_id', dependent: :destroy
  has_many :created_invitations, class_name: 'Invitation', foreign_key: 'created_by_id', dependent: :destroy

  # Relations pour les destinataires de cadeaux
  has_many :gift_recipients, dependent: :destroy
  has_many :received_gift_ideas, through: :gift_recipients, source: :gift_idea

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :standard?
  validates :email, uniqueness: { allow_blank: true }, if: :managed?
  validates :password, presence: true, if: -> { standard? && password_required? }
  validates :account_type, presence: true, inclusion: { in: %w[standard managed] }
  validates :parent_id, presence: true, if: :managed?
  validates :parent_id, absence: true, if: :standard?

  # Callbacks
  before_validation :set_default_account_type

  # Methods
  def managed?
    account_type == 'managed'
  end

  def standard?
    account_type.nil? || account_type == 'standard'
  end

  def common_groups_with(user)
    groups & user.groups
  end

  def has_common_group_with?(user)
    common_groups_with(user).any?
  end

  # Retourne les IDs des utilisateurs avec lesquels l'utilisateur partage un groupe
  # OU avec lesquels un de ses enfants partage un groupe
  # Inclut également les IDs des enfants managés (même sans groupes)
  def common_groups_with_users_ids
    # Récupérer les IDs des groupes de l'utilisateur
    group_ids = Membership.where(user_id: self.id).pluck(:group_id)

    # Récupérer les IDs des enfants
    children_ids = User.where(parent_id: self.id).pluck(:id)

    # Ajouter les IDs des groupes des enfants si il y en a
    if children_ids.any?
      children_group_ids = Membership
        .where(user_id: children_ids)
        .pluck(:group_id)
      group_ids = (group_ids + children_group_ids).uniq
    end

    # Si pas de groupes, retourner uniquement les IDs des enfants managés
    return children_ids if group_ids.empty?

    # Récupérer les utilisateurs partageant ces groupes, sauf soi-même
    user_ids_from_groups = User.joins(:memberships)
        .where(memberships: { group_id: group_ids })
        .where.not(id: self.id)
        .distinct
        .pluck(:id)

    # Combiner avec les enfants managés et éliminer les doublons
    (user_ids_from_groups + children_ids).uniq
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

  def set_default_account_type
    self.account_type ||= 'standard'
  end
end
