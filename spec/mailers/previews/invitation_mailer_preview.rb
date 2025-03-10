# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer_mailer
class InvitationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/invitation_mailer_mailer/invitation_created
  def invitation_created
    InvitationMailer.invitation_created
  end

end
