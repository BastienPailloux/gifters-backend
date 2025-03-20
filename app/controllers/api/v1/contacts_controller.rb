class Api::V1::ContactsController < Api::V1::BaseController
  # Skip authentication for contact form submissions
  skip_before_action :authenticate_user!

  def create
    # Retrieve contact form parameters
    name = params[:name]
    email = params[:email]
    subject = params[:subject]
    message = params[:message]

    # Validate required parameters
    if name.blank? || email.blank? || message.blank?
      return render json: {
        status: { message: 'Missing required fields' },
        errors: ['All fields are required']
      }, status: :unprocessable_entity
    end

    # Send email via ContactMailer
    begin
      ContactMailer.contact_message(name, email, subject, message).deliver_now

      # Return success response
      render json: {
        status: { message: 'Message sent successfully' }
      }, status: :ok
    rescue => e
      # Log error and return error response
      Rails.logger.error("Error sending contact email: #{e.message}")
      render json: {
        status: { message: 'Failed to send message' },
        errors: [e.message]
      }, status: :internal_server_error
    end
  end
end
