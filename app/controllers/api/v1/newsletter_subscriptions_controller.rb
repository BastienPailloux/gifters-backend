module Api
  module V1
    class NewsletterSubscriptionsController < BaseController
      skip_before_action :authenticate_user!

      def create
        subscription_params = newsletter_subscription_params
        email = subscription_params[:email]
        list_id = subscription_params[:list_id] || ENV['BREVO_LIST_ID']
        redirect_url = subscription_params[:redirect_url] || ENV['FRONTEND_URL']

        unless email.present? && valid_email?(email)
          return render json: { error: I18n.t('newsletter.errors.invalid_email') }, status: :unprocessable_entity
        end

        begin
          # Utiliser le service pour gérer l'abonnement
          response = BrevoService.subscribe_contact(email, list_id, redirect_url)

          if response[:success]
            render json: { message: I18n.t('newsletter.subscription_success') }, status: :ok
          else
            render json: { error: response[:error] || I18n.t('newsletter.errors.generic') }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error("Newsletter subscription error: #{e.message}")
          render json: { error: I18n.t('newsletter.errors.generic') }, status: :internal_server_error
        end
      end

      # Ajouter une action pour désabonner un contact
      def destroy
        email = params[:email]

        unless email.present? && valid_email?(email)
          return render json: { error: I18n.t('newsletter.errors.invalid_email') }, status: :unprocessable_entity
        end

        begin
          # Utiliser le service pour gérer le désabonnement
          response = BrevoService.unsubscribe_contact(email, params[:list_id])

          if response[:success]
            render json: { message: I18n.t('newsletter.unsubscription_success', default: 'Successfully unsubscribed from newsletter') }, status: :ok
          else
            render json: { error: response[:error] || I18n.t('newsletter.errors.generic') }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error("Newsletter unsubscription error: #{e.message}")
          render json: { error: I18n.t('newsletter.errors.generic') }, status: :internal_server_error
        end
      end

      private

      def newsletter_subscription_params
        # Gestion des différentes structures de paramètres possibles
        if params[:newsletter_subscription].present? && params[:newsletter_subscription][:newsletter].present?
          # Double imbrication: { newsletter_subscription: { newsletter: { email: ... } } }
          params[:newsletter_subscription].require(:newsletter).permit(:email, :list_id, :redirect_url)
        elsif params[:newsletter].present?
          # Imbrication simple: { newsletter: { email: ... } }
          params.require(:newsletter).permit(:email, :list_id, :redirect_url)
        else
          # Pas d'imbrication: { email: ... }
          params.permit(:email, :list_id, :redirect_url)
        end
      end

      def valid_email?(email)
        email =~ URI::MailTo::EMAIL_REGEXP
      end
    end
  end
end
