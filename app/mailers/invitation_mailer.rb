class InvitationMailer < ApplicationMailer
  default from: 'norepy@gifters.fr'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.invitation_created.subject
  #
  def invitation_created(invitation)
    @invitation = invitation
    @sender = invitation.sender
    @group = invitation.group
    @token = invitation.token

    # Determine preferred locale based on sender's locale
    locale = @sender.locale

    # Validate locale
    unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
      locale = I18n.default_locale
    end

    @invitation_url = "#{ENV['FRONTEND_URL'] || 'http://localhost:3000'}/invitations/#{@invitation.token}"

    I18n.with_locale(locale) do
      mail(
        to: @invitation.email,
        subject: I18n.t('mailers.invitation.created.subject', group: @group.name)
      )
    end
  end

  # Envoie un email lorsqu'une invitation est acceptée
  def invitation_accepted(invitation, user)
    @invitation = invitation
    @user = user
    @group = invitation.group

    # Obtenir l'administrateur du groupe (le premier admin ou le créateur de l'invitation)
    admin_user = @group.admin_users.first || invitation.created_by
    @admin = admin_user

    # Determine preferred locale based on admin's locale
    locale = @admin.locale
    Rails.logger.info("Sending invitation accepted email with locale: #{locale}")

    # Validate locale
    unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
      Rails.logger.info("Invalid locale #{locale}, defaulting to #{I18n.default_locale}")
      locale = I18n.default_locale
    end

    @group_url = group_url(@group)

    I18n.with_locale(locale) do
      mail(
        to: @admin.email,
        subject: I18n.t('mailers.invitation.accepted.subject', user: @user.name)
      )
    end
  end

  private

  def group_url(group)
    "#{ENV['FRONTEND_URL'] || 'http://localhost:3000'}/groups/#{group.id}"
  end
end
