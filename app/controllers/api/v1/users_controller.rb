module Api
  module V1
    class UsersController < Api::V1::BaseController
      before_action :set_user, only: [:show, :update, :destroy, :update_locale]
      before_action :authorize_user, only: [:update, :destroy]

      # GET /api/v1/users
      def index
        @users = User.all
        users_data = @users.map { |user| user.as_json(only: [:id, :name, :email]) }
        render json: { users: users_data }
      end

      # GET /api/v1/users/:id
      def show
        render json: { user: @user.as_json(except: [:encrypted_password, :reset_password_token, :reset_password_sent_at]) }
      end

      # GET /api/v1/users/shared_users
      def shared_users
        # Cette action ne nécessite pas de paramètres car elle utilise current_user
        user_ids = current_user.common_groups_with_users_ids
        render json: { user_ids: user_ids }
      end

      # PUT /api/v1/users/:id
      def update
        # Si le mot de passe est modifié, vérifier l'ancien mot de passe
        if user_params[:password].present?
          unless @user.valid_password?(user_params[:current_password])
            render json: { errors: ['Current password is incorrect'] }, status: :unprocessable_entity
            return
          end
        end

        # Filtrer les paramètres pour exclure current_password qui n'est pas un attribut du modèle
        update_params = user_params.except(:current_password)

        if @user.update(update_params)
          render json: { user: @user.as_json(except: [:encrypted_password, :reset_password_token, :reset_password_sent_at]) }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        head :no_content
      end

      # PATCH/PUT /api/v1/users/:id/update_locale
      def update_locale
        # Autorise uniquement la mise à jour de sa propre locale
        if @user.id.to_s == current_user.id.to_s
          if @user.update(locale_params)
            render json: {
              status: { code: 200, message: 'Locale updated successfully' },
              data: { locale: @user.locale }
            }, status: :ok
          else
            render json: {
              status: { code: 422, message: 'Could not update locale' },
              errors: @user.errors.full_messages
            }, status: :unprocessable_entity
          end
        else
          render json: {
            status: { code: 403, message: 'Not authorized to update this user locale' }
          }, status: :forbidden
        end
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
        params.require(:user).permit(
          :name,
          :email,
          :password,
          :password_confirmation,
          :current_password,
          :birthday,
          :phone_number,
          :address,
          :city,
          :state,
          :zip_code,
          :country
        )
      end

      def locale_params
        params.require(:user).permit(:locale)
      end
    end
  end
end
