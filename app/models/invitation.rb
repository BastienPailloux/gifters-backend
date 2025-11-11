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
    frontend_host = ENV['FRONTEND_URL'] || case Rails.env
                                            when 'production'
                                              'https://gifters.fr'
                                            when 'staging'
                                              'https://staging.gifters.fr'
                                            else
                                              'http://localhost:5173'
                                            end

    "#{frontend_host}/invitation/join?token=#{CGI.escape(token)}"
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
