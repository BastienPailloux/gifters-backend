module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      skip_before_action :verify_authenticity_token
      before_action :configure_permitted_parameters, only: [:create]
      def create

        # Récupérer les paramètres d'authentification
        auth_params = sign_in_params
        email = auth_params[:email]
        password = auth_params[:password]


        # Vérifier si l'utilisateur existe
        user = User.find_by(email: email)

        if user && user.valid_password?(password)

          # Connecter l'utilisateur avec Devise
          sign_in(resource_name, user)

          # Le token JWT est automatiquement généré par devise-jwt
          token = request.env['warden-jwt_auth.token']

          # Répondre avec succès
          render json: {
            status: { code: 200, message: 'Logged in successfully' },
            data: {
              user: {
                id: user.id,
                name: user.name,
                email: user.email
              },
              token: token
            }
          }, status: :ok
        else
          # Répondre avec erreur
          render json: {
            status: { code: 401, message: 'Invalid email or password' }
          }, status: :unauthorized
        end
      end

      # Méthode standard pour la déconnexion
      def destroy
        super
      end

      private

      def sign_in_params
        filtered_params = if params[:session] && params[:session][:user]
          params.require(:session).require(:user).permit(:email, :password)
        else
          params.require(:user).permit(:email, :password)
        end

        filtered_params  # Retourner explicitement les paramètres filtrés
      end

      def respond_with(resource, _opts = {})
        token = request.env['warden-jwt_auth.token']

        render json: {
          status: { code: 200, message: 'Logged in successfully' },
          data: {
            user: {
              id: resource.id,
              name: resource.name,
              email: resource.email
            },
            token: token
          }
        }, status: :ok
      end

      def respond_to_on_destroy
        render json: {
          status: { code: 200, message: 'Logged out successfully' }
        }, status: :ok
      end

      # Configuration des paramètres autorisés
      def configure_permitted_parameters
        # Personnaliser le sanitizer pour autoriser les deux formats de paramètres
        devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])

        # Vérifier et ajouter les paramètres de session si nécessaire
        if params[:session] && params[:session][:user]
          params[:user] = params[:session][:user]
          # Force le marquage des paramètres comme étant autorisés
          params.require(:user).permit(:email, :password)
        end
      end
    end
  end
end
