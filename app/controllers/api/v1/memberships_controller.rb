module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_group
      before_action :ensure_user_in_group

      # GET /api/v1/groups/:group_id/memberships
      def index
        @memberships = @group.memberships.includes(:user)
        render json: @memberships.as_json(include: { user: { only: [:id, :name, :email] } },
                                         methods: [:user_name, :user_email])
      end

      private

      def set_group
        @group = Group.find_by(id: params[:group_id])

        unless @group
          render json: { error: 'Group not found' }, status: :not_found
          return
        end
      end

      def ensure_user_in_group
        unless current_user_membership
          render json: { error: 'You are not a member of this group' }, status: :forbidden
        end
      end

      def current_user_membership
        @current_user_membership ||= @group.memberships.find_by(user: current_user)
      end
    end
  end
end
