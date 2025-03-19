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

    # Récupérer la préférence de langue de l'utilisateur ou utiliser la langue par défaut
    user_locale = record.locale.presence || I18n.default_locale.to_s

    # S'assurer que la locale est parmi les locales disponibles
    if I18n.available_locales.map(&:to_s).include?(user_locale)
      locale = user_locale
    else
      locale = I18n.default_locale.to_s
    end

    # Rails Logger pour débogage
    Rails.logger.info("DeviseMailer#reset_password_instructions - Using locale: #{locale}")

    # Définir temporairement la locale pour cet email
    I18n.with_locale(locale) do
      # La méthode avec super utilisera automatiquement le bon template
      # basé sur la locale courante (reset_password_instructions.fr.html.erb)
      super
    end
  end
end
