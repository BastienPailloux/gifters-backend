module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      private

      def respond_with(resource, _opts = {})
        render json: {
          status: { code: 200, message: 'Logged in successfully' },
          data: {
            user: {
              id: resource.id,
              name: resource.name,
              email: resource.email
            },
            token: request.env['warden-jwt_auth.token']
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
