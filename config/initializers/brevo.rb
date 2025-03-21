# Configuration de l'API Brevo
# Documentation: https://github.com/getbrevo/brevo-ruby

Brevo.configure do |config|
  # API key disponible dans l'interface Brevo sous "SMTP & API" > "API Keys"
  config.api_key['api-key'] = ENV['BREVO_API_KEY']

  # Configuration optionnelle du timeout
  config.timeout = 30 # secondes

  # Configuration du mode debug en développement
  config.debugging = Rails.env.development?
end
