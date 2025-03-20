# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer_mailer
class ContactMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/contact_mailer_mailer/contact_message
  def contact_message
    ContactMailer.contact_message
  end

end
