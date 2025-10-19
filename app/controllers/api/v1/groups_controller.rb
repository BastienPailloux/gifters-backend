module Api
  module V1
    class GroupsController < Api::V1::BaseController
      before_action :set_children, only: [:index], if: -> { params[:with_children].present? }
      before_action :set_user, only: [:create, :show, :update, :destroy, :leave], if: -> { params[:user_id].present? }
      before_action :set_group, only: [:show, :update, :destroy, :leave]
      before_action :ensure_member, only: [:show, :update, :destroy, :leave]
      before_action :ensure_admin, only: [:update, :destroy]

      # GET /api/v1/groups
      def index
        @user = current_user
        @groups = @user.groups
      end

      # GET /api/v1/groups/:id
      def show
        @memberships = @group.memberships.includes(:user)
      end

      # POST /api/v1/groups
      def create
        @group = Group.new(group_params)
        @group.creator = @user || current_user

        if @group.save
          @group.memberships.create(user: @user || current_user, role: 'admin')
          render status: :created
        else
          render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/groups/:id
      def update
        if @group.update(group_params)
          render :update
        else
          render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:id
      def destroy
        @group.destroy
        head :no_content
      end

      # DELETE /api/v1/groups/:id/leave
      def leave
        # Vérifier si l'utilisateur est le dernier administrateur du groupe
        if @group.admin_users == [current_user] || @group.admin_users == [@user]
          render json: { error: 'You cannot leave the group as you are the last admin' }, status: :unprocessable_entity
          return
        end

        # Supprimer l'utilisateur du groupe
        membership = @group.memberships.find_by(user: @user || current_user)
        membership.destroy if membership

        render json: { message: 'Successfully left the group' }, status: :ok
      end

      private

      def set_group
        @group = Group.find_by(id: params[:id])
        render json: { error: 'Group not found' }, status: :not_found unless @group
      end

      def ensure_member
        unless @group && (@group.users.include?(current_user) || @group.users.include?(@user))
          render json: { error: 'You are not a member of this group' }, status: :forbidden
        end
        true
      end

      def ensure_admin
        return unless ensure_member

        unless @group.admin_users.include?(current_user) || @group.admin_users.include?(@user)
          action = action_name == 'update' ? 'update' : 'delete'
          render json: { error: "You must be an admin to #{action} this group" }, status: :forbidden
        end
        true
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end

      def set_children
        @children = current_user.children.includes(:groups)
      end

      def set_user
        @user = User.find(params[:user_id])
        unless current_user.can_access_as_parent?(@user)
          render json: { error: 'Forbidden: You are not the parent of this account' }, status: :forbidden
        end
      end
    end
  end
end
