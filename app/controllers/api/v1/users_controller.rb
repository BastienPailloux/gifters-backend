module Api
  module V1
    class UsersController < Api::V1::BaseController
      before_action :set_user, only: [:show, :update, :destroy]
      before_action :authorize_user, only: [:update, :destroy]

      # GET /api/v1/users
      def index
        @users = User.all
        users_data = @users.map { |user| user.as_json(only: [:id, :name, :email]) }
        render json: { users: users_data }
      end

      # GET /api/v1/users/:id
      def show
        render json: { user: @user.as_json(only: [:id, :name, :email]) }
      end

      # PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: { user: @user.as_json(only: [:id, :name, :email]) }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        head :no_content
      end

      private

      def set_user
        @user = User.find_by(id: params[:id])
        unless @user
          render json: { error: 'User not found' }, status: :not_found
          return
        end
      end

      def authorize_user
        unless @user == current_user
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end

      def user_params
        params.require(:user).permit(:name, :email)
      end
    end
  end
end
