module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def authenticate_user!
        header = request.headers['Authorization']
        token = header.split(' ').last if header

        if token
          begin
            decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)
            @current_user_id = decoded_token[0]['user_id']
          rescue JWT::DecodeError
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
      end

      def current_user
        @current_user ||= User.find_by(id: @current_user_id)
      end

      def not_found
        render json: { error: 'Resource not found' }, status: :not_found
      end
    end
  end
end
