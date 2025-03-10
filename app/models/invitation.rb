class Invitation < ApplicationRecord
  # Associations
  belongs_to :group
  belongs_to :created_by, class_name: 'User'

  # Constants
  ROLES = %w[member admin].freeze

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :used, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :generate_token, on: :create

  # Scopes
  scope :unused, -> { where(used: false) }

  # Methods
  def mark_as_used!
    update!(used: true)
  end

  def invitation_url
    Rails.application.routes.url_helpers.accept_invitation_url(token: token, host: Rails.application.config.action_mailer.default_url_options[:host])
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
