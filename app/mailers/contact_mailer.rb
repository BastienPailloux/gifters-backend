class ContactMailer < ApplicationMailer
  default from: 'no-reply@gifters.fr'

  # Send a contact form message to the admin team
  # @param [String] name The name of the contact
  # @param [String] email The email of the contact
  # @param [String] subject The subject of the message
  # @param [String] message The message content
  def contact_message(name, email, subject, message)
    @name = name
    @email = email
    @subject = subject || "Message from Gifters Contact Form"
    @message = message
    @sent_at = Time.current

    mail(
      from: @email,
      to: "contact@gifters.fr",
      subject: "Contact Form: #{@subject}",
      reply_to: email
    )
  end
end
