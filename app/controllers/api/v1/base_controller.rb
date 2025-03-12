module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds
      respond_to :json

      include Devise::Controllers::Helpers
      before_action :authenticate_user!

      # Définir current_user comme scope pour les sérialiseurs
      serialization_scope :current_user

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def authenticate_user!
        unless current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def current_user
        @current_user ||= warden_user || jwt_user
      end

      def warden_user
        warden.authenticate(scope: :user) if warden.present?
      end

      def jwt_user
        return nil unless auth_header.present?

        token = auth_header.split(' ').last
        begin
          decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
          User.find_by(id: decoded['user_id'])
        rescue JWT::DecodeError
          nil
        end
      end

      def auth_header
        request.headers['Authorization']
      end

      def print_params
        Rails.logger.info("BaseController#print_params - Paramètres reçus: #{params.inspect}")
      end

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
        devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
      end

      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end
    end
  end
end
