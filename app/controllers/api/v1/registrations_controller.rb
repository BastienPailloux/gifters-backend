module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      # Surcharge pour ajouter des logs et générer un token manuellement
      def create
        Rails.logger.info("Registrations#create - Tentative d'inscription avec params: #{params.inspect}")

        # Extraire les paramètres d'inscription
        user_params = params[:user] || (params[:session] && params[:session][:user])

        unless user_params
          Rails.logger.error("Registrations#create - Paramètres utilisateur non trouvés")
          return render json: { error: 'Paramètres utilisateur manquants' }, status: :unprocessable_entity
        end

        Rails.logger.info("Registrations#create - Paramètres utilisateur: #{user_params.inspect}")

        # Créer l'utilisateur en utilisant Devise
        build_resource(sign_up_params)

        Rails.logger.info("Registrations#create - Validation de l'utilisateur: #{resource.valid?}")

        if resource.valid?
          # Enregistrer l'utilisateur
          resource.save

          # Connecter l'utilisateur
          sign_in(:user, resource)

          # Générer un token JWT manuellement
          payload = { 'user_id' => resource.id }
          token = JWT.encode(payload, Rails.application.credentials.secret_key_base)

          Rails.logger.info("Registrations#create - Inscription réussie, token généré manuellement")

          # Réponse positive
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
          Rails.logger.error("Registrations#create - Erreurs de validation: #{resource.errors.full_messages}")

          render json: {
            status: { code: 422, message: 'User could not be created' },
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def sign_up_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      rescue ActionController::ParameterMissing => e
        Rails.logger.error("Registrations#sign_up_params - Erreur de paramètres: #{e.message}")
        # Tenter d'utiliser les paramètres de session si disponibles
        if params[:session] && params[:session][:user]
          params[:session].require(:user).permit(:name, :email, :password, :password_confirmation)
        else
          raise e
        end
      end
    end
  end
end
