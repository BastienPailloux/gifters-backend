module Api
  module V1
    class InvitationsController < Api::V1::BaseController
      before_action :set_group, only: [:index, :create, :send_email]
      before_action :set_invitation, only: [:show, :destroy, :accept]
      before_action :authorize_invitation

      # GET /api/v1/groups/:group_id/invitations
      def index
        @invitations = policy_scope(@group.invitations).includes(:created_by)

        # Assurer que le rendu est toujours un tableau, même vide
        if @invitations.empty?
          render json: { invitations: [] }
        else
          render json: { invitations: @invitations.as_json(include: { created_by: { only: [:id, :name, :email] } }) }
        end
      end

      # GET /api/v1/invitations/:token
      def show
        render json: @invitation.as_json(include: {
          group: { only: [:id, :name] },
          created_by: { only: [:id, :name, :email] }
        })
      end

      # POST /api/v1/groups/:group_id/invitations
      def create
        @invitation = @group.invitations.new(invitation_params)
        @invitation.created_by = current_user

        if @invitation.save

          render json: {
            invitation: @invitation.as_json,
            invitation_url: @invitation.invitation_url,
            token: @invitation.token
          }, status: :created
        else
          render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/groups/:group_id/invitations/send_email
      def send_email
        # Chercher d'abord une invitation existante pour ce groupe
        @invitation = @group.invitations.find_or_initialize_by(role: invitation_params[:role] || 'member')

        # Si l'invitation est nouvelle, définir le créateur
        if @invitation.new_record?
          @invitation.created_by = current_user
          unless @invitation.save
            render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity
            return
          end
        end

        # Maintenant, envoyer l'email avec l'invitation (existante ou nouvelle)
        if email_params[:email].present?
          begin
            # Utiliser deliver_now en environnement de test pour que les tests puissent vérifier l'envoi
            if Rails.env.test?
              InvitationMailer.invitation_created(@invitation, email_params[:email]).deliver_now
            else
              InvitationMailer.invitation_created(@invitation, email_params[:email]).deliver_later
            end

            render json: {
              message: "Invitation sent to #{email_params[:email]}",
              invitation: @invitation.as_json,
              invitation_url: @invitation.invitation_url,
              token: @invitation.token
            }, status: :ok
          rescue => e
            Rails.logger.error("Erreur lors de l'envoi du mail d'invitation: #{e.message}")
            render json: {
              error: "Failed to send invitation email: #{e.message}",
              invitation: @invitation.as_json,
              token: @invitation.token
            }, status: :internal_server_error
          end
        else
          render json: { error: "Email address is required" }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/invitations/:id
      def destroy
        @invitation.destroy
        head :no_content
      end

      # POST /api/v1/invitations/accept
      def accept
        # Par défaut, si user_ids n'est pas fourni, utiliser l'utilisateur actuel
        user_ids = if params[:user_ids].present?
          Array(params[:user_ids]).map(&:to_i)
        else
          [current_user.id]
        end

        service = Invitations::InvitationAcceptanceService.new

        result = service.call(
          invitation: @invitation,
          user_ids: user_ids,
          current_user: current_user
        )

        case result
        when Dry::Monads::Success
          render json: result.value!, status: :ok
        when Dry::Monads::Failure
          render json: result.failure, status: :unprocessable_entity
        end
      end

      private

      def set_group
        @group = Group.find_by(id: params[:group_id])

        unless @group
          render json: { error: 'Group not found' }, status: :not_found
          return
        end
      end

      def set_invitation
        @invitation = Invitation.find_by(token: params[:token] || params[:id])

        unless @invitation
          render json: { error: 'Invitation not found' }, status: :not_found
          return
        end
      end

      def invitation_params
        params.require(:invitation).permit(:role)
      end

      # Méthode sécurisée pour filtrer les paramètres email et message
      def email_params
        params.permit(:email, :message)
      end


      def authorize_invitation
        case action_name
        when 'index', 'create', 'send_email'
          authorize @group, :manage_invitations?
        when 'show', 'destroy'
          authorize @invitation
        when 'accept'
          authorize @invitation, :accept?
        end
      end
    end
  end
end
