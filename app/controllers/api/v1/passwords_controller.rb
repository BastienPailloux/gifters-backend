module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      # POST /api/v1/password - Création d'une demande de réinitialisation
      def create
        self.resource = resource_class.send_reset_password_instructions(resource_params)

        if successfully_sent?(resource)
          render json: {
            status: { code: 200, message: 'Reset password instructions sent successfully' }
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: 'Could not send reset instructions' },
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/password - Réinitialisation du mot de passe avec le token
      def update
        self.resource = resource_class.reset_password_by_token(resource_params)

        if resource.errors.empty?
          render json: {
            status: { code: 200, message: 'Password updated successfully' }
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: 'Could not reset password' },
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def resource_params
        params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
      end
    end
  end
end
