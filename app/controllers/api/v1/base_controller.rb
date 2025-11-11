module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds
      respond_to :json

      include Devise::Controllers::Helpers
      include Pundit::Authorization

      before_action :authenticate_user!
      before_action :set_current_user

      # Passer current_user aux sérialiseurs comme scope
      def default_serializer_options
        { scope: current_user, scope_name: :current_user }
      end

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

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
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :newsletter_subscription])
        devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password, :newsletter_subscription])
      end

      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end

      def user_not_authorized(exception)
        policy_name = exception.policy.class.to_s.underscore
        error_message = I18n.t("#{policy_name}.#{exception.query}", scope: "pundit", default: 'You are not authorized to perform this action.')
        render json: { error: error_message }, status: :forbidden
      end

      # Rendre current_user disponible dans les vues
      def set_current_user
        @current_user = current_user
      end

      # Définir pundit_user pour les policies dans les vues
      def pundit_user
        current_user
      end
    end
  end
end
