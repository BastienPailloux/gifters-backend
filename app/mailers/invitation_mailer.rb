class InvitationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.invitation_created.subject
  #
  def invitation_created(invitation, recipient_email)
    @invitation = invitation
    @group = invitation.group
    @sender = invitation.created_by
    @token = invitation.token
    @invitation_url = invitation.invitation_url

    mail(
      to: recipient_email,
      subject: "Vous avez été invité à rejoindre un groupe sur Gifters"
    )
  end

  # Envoie un email lorsqu'une invitation est acceptée
  def invitation_accepted(invitation, user)
    @invitation = invitation
    @group = invitation.group
    @user = user
    @admin = invitation.created_by
    @group_url = group_url(@group)

    mail(
      to: @admin.email,
      subject: "Un utilisateur a rejoint votre groupe sur Gifters"
    )
  end

  private

  def group_url(group)
    # Utiliser les options de configuration de l'environnement actuel
    options = Rails.application.config.action_mailer.default_url_options || {}

    # Construire l'URL avec le helper de route
    Rails.application.routes.url_helpers.api_v1_group_url(
      group,
      **options
    )
  end
end
