module Api
  module V1
    class InvitationsController < BaseController
      before_action :set_group, only: [:index, :create]
      before_action :ensure_user_is_admin, only: [:index, :create]
      before_action :set_invitation, only: [:show, :destroy]

      # GET /api/v1/groups/:group_id/invitations
      def index
        @invitations = @group.invitations.includes(:created_by)
        render json: @invitations.as_json(include: { created_by: { only: [:id, :name, :email] } })
      end

      # GET /api/v1/invitations/:token
      def show
        if @invitation.used?
          render json: { error: 'This invitation has already been used' }, status: :unprocessable_entity
          return
        end

        render json: @invitation.as_json(include: {
          group: { only: [:id, :name] },
          created_by: { only: [:id, :name, :email] }
        })
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

      def ensure_user_is_admin
        unless current_user_is_admin_of_group?(@group)
          render json: { error: 'You must be an admin to manage invitations' }, status: :forbidden
          return
        end
      end

      def current_user_is_admin_of_group?(group)
        membership = group.memberships.find_by(user: current_user)
        membership&.role == 'admin'
      end

      def invitation_params
        params.require(:invitation).permit(:role)
      end
    end
  end
end
