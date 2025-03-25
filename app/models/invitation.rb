class Invitation < ApplicationRecord
  # Associations
  belongs_to :group
  belongs_to :created_by, class_name: 'User'

  # Constants
  ROLES = %w[member admin].freeze

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: ROLES }

  # Callbacks
  before_validation :generate_token, on: :create

  # Methods
  def invitation_url
    # Déterminer l'hôte à utiliser
    host = Rails.application.config.action_mailer.default_url_options&.dig(:host)

    # Si l'hôte n'est pas configuré, utiliser une valeur par défaut basée sur l'environnement
    unless host.present?
      host = case Rails.env
             when 'production'
               'api.gifters.fr'
             when 'staging'
               'api-staging.gifters.fr'
             else
               'localhost:3000'
             end
      Rails.logger.warn("Host not configured for invitation_url, using default: #{host}")
    end

    # Construire l'URL avec le helper de route en spécifiant explicitement l'hôte
    Rails.application.routes.url_helpers.accept_api_v1_invitations_url(
      token: token,
      host: host
    )
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
