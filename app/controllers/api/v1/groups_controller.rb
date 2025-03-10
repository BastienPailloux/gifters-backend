module Api
  module V1
    class GroupsController < BaseController
      before_action :authenticate_user!
      before_action :set_group, only: [:show, :update, :destroy, :join, :leave]
      before_action :ensure_member, only: [:show]
      before_action :ensure_admin, only: [:update, :destroy]

      # GET /api/v1/groups
      def index
        @groups = current_user.groups
        render json: @groups, only: [:id, :name, :description, :invite_code]
      end

      # GET /api/v1/groups/:id
      def show
        members = @group.memberships.includes(:user).map do |membership|
          {
            id: membership.user.id,
            name: membership.user.name,
            email: membership.user.email,
            role: membership.role
          }
        end

        render json: {
          id: @group.id,
          name: @group.name,
          description: @group.description,
          invite_code: @group.invite_code,
          members: members
        }
      end

      private

      def set_group
        @group = Group.find_by(id: params[:id])
        render json: { error: 'Group not found' }, status: :not_found unless @group
      end

      def ensure_member
        unless @group && @group.users.include?(current_user)
          render json: { error: 'You are not a member of this group' }, status: :forbidden
        end
      end

      def ensure_admin
        unless @group && @group.admin_users.include?(current_user)
          render json: { error: 'You must be an admin to update this group' }, status: :forbidden
        end
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end
    end
  end
end
