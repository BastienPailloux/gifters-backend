module Api
  module V1
    class UsersController < Api::V1::BaseController
      before_action :set_user, only: [:show, :update, :destroy, :update_locale]
      before_action :authorize_user, only: [:update, :destroy]

      # GET /api/v1/users
      def index
        @users = User.all
      end

      # GET /api/v1/users/:id

      # GET /api/v1/users/shared_users
      def shared_users
        @user_ids = current_user.common_groups_with_users_ids
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

        # Vérifier si le statut d'abonnement à la newsletter a changé
        newsletter_changed = false
        if user_params.key?(:newsletter_subscription)
          newsletter_changed = @user.newsletter_subscription_changed?(user_params[:newsletter_subscription])
        end

        old_newsletter_status = @user.newsletter_subscription

        # Filtrer les paramètres pour exclure current_password qui n'est pas un attribut du modèle
        update_params = user_params.except(:current_password)

        if @user.update(update_params)
          # Si le statut d'abonnement à la newsletter a changé, mettre à jour dans Brevo
          if newsletter_changed
            @user.update_brevo_subscription
          end

          render :update
        else
          # En cas d'échec, restaurer l'ancien statut d'abonnement si nécessaire
          if newsletter_changed
            @user.update_column(:newsletter_subscription, old_newsletter_status)
          end

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
          :country,
          :newsletter_subscription
        )
      end

      def locale_params
        params.require(:user).permit(:locale)
      end
    end
  end
end
