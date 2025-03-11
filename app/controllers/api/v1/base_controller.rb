module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def authenticate_user!
        if request.headers['Authorization'].present?
          header = request.headers['Authorization']
          token = header.split(' ').last if header

          Rails.logger.info("BaseController#authenticate_user! - Token présent: #{token ? 'oui' : 'non'}")

          if token
            begin
              # Décoder le token JWT
              decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)
              user_id = decoded_token[0]['user_id']

              # Chercher l'utilisateur
              @current_user = User.find_by(id: user_id)

              if @current_user
                Rails.logger.info("BaseController#authenticate_user! - Utilisateur authentifié: #{@current_user.email}")
                return
              else
                Rails.logger.error("BaseController#authenticate_user! - Utilisateur non trouvé pour l'ID: #{user_id}")
              end
            rescue JWT::DecodeError => e
              Rails.logger.error("BaseController#authenticate_user! - Erreur de décodage JWT: #{e.message}")
            end
          end
        else
          Rails.logger.warn("BaseController#authenticate_user! - Aucun en-tête Authorization")
        end

        render json: { error: 'Non autorisé' }, status: :unauthorized
      end

      def current_user
        @current_user
      end

      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end
    end
  end
end
