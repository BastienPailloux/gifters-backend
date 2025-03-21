class User < ApplicationRecord
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
end
