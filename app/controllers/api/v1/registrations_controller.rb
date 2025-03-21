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

          # Ajouter l'utilisateur à la liste de contacts Brevo
          subscribe_to_brevo(resource)

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
        params.require(:user).permit(:name, :email, :password, :password_confirmation, :locale, :newsletter_subscription)
      rescue ActionController::ParameterMissing => e
        # Informer sur l'erreur
        Rails.logger.error("RegistrationsController#sign_up_params - Erreur: #{e.message}")
        {}
      end

      # Méthode pour ajouter l'utilisateur à la liste de contacts Brevo
      def subscribe_to_brevo(user)
        # Vérifier si l'utilisateur a accepté de s'abonner à la newsletter
        # Si newsletter_subscription n'est pas défini, on considère qu'il n'y a pas de consentement
        unless user.respond_to?(:newsletter_subscription) && user.newsletter_subscription
          return
        end

        begin
          # Utiliser le service Brevo pour l'inscription
          response = BrevoService.subscribe_contact(user.email)

          unless response[:success]
            Rails.logger.error("RegistrationsController#subscribe_to_brevo - Erreur lors de l'ajout à Brevo: #{response[:error]}")
          end

        rescue => e
          Rails.logger.error("RegistrationsController#subscribe_to_brevo - Exception: #{e.message}")
        end
      end
    end
  end
end
