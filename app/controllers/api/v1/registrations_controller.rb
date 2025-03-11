module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      # Adaptation pour gérer différentes structures de paramètres
      def create
        Rails.logger.info("RegistrationsController#create - Tentative d'inscription")

        # Adaptation des paramètres selon différents formats
        if params[:session] && params[:session][:user]
          params[:user] = params[:session][:user]
        elsif params[:registration] && params[:registration][:user]
          params[:user] = params[:registration][:user]
        end

        # Utilisation standard de la méthode Devise
        super
      end

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          token = request.env['warden-jwt_auth.token']
          Rails.logger.info("RegistrationsController#respond_with - Inscription réussie, token: #{token.present?}")

          render json: {
            status: { code: 200, message: 'Signed up successfully' },
            data: {
              user: {
                id: resource.id,
                name: resource.name,
                email: resource.email
              },
              token: token
            }
          }, status: :ok
        else
          Rails.logger.error("RegistrationsController#respond_with - Erreur: #{resource.errors.full_messages.join(', ')}")
          render json: {
            status: { code: 422, message: 'User could not be created' },
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def sign_up_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      rescue ActionController::ParameterMissing => e
        # Informer sur l'erreur
        Rails.logger.error("RegistrationsController#sign_up_params - Erreur: #{e.message}")
        {}
      end
    end
  end
end
