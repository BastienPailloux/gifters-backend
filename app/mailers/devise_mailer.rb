class DeviseMailer < Devise::Mailer
  # Configuration par défaut
  default from: 'noreply@gifters.com'
  layout 'mailer'

  # Redéfinition de la méthode pour la réinitialisation de mot de passe
  def reset_password_instructions(record, token, opts = {})
    # On passe l'URL du frontend comme paramètre pour que le template puisse l'utiliser
    @frontend_url = Rails.application.config.frontend_url

    # Inclure le token dans l'email via la variable @token (utilisée dans le template)
    @token = token

    # Appel à la méthode originale
    super
  end
end
