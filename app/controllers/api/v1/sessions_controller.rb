module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      def create
        # Extraction des paramètres d'authentification
        email = params.dig(:user, :email) || params.dig(:session, :user, :email)
        password = params.dig(:user, :password) || params.dig(:session, :user, :password)

        # Recherche de l'utilisateur par email
        user = User.find_by(email: email)

        if user
          # Test direct du mot de passe avec Devise
          valid_password = user.valid_password?(password)

          if valid_password
            sign_in(:user, user)

            # Générer un token JWT manuellement
            payload = {
              'user_id' => user.id,
              'jti' => SecureRandom.uuid,
              'exp' => 24.hours.from_now.to_i
            }
            token = JWT.encode(payload, Rails.application.credentials.secret_key_base)

            # Réponse positive
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
            render json: {
              error: 'Email ou mot de passe invalide',
              debug: 'Mot de passe incorrect'
            }, status: :unauthorized
          end
        else
          render json: {
            error: 'Email ou mot de passe invalide',
            debug: 'Utilisateur non trouvé'
          }, status: :unauthorized
        end
      end

      private

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
        if current_user
          render json: {
            status: { code: 200, message: 'Logged out successfully' }
          }, status: :ok
        else
          render json: {
            status: { code: 401, message: 'Unauthorized' }
          }, status: :unauthorized
        end
      end
    end
  end
end
