module Api
  module V1
    class GroupsController < Api::V1::BaseController
      before_action :set_children, only: [:index], if: -> { params[:with_children].present? }
      before_action :set_user, only: [:create, :show, :update, :destroy, :leave], if: -> { params[:user_id].present? }
      before_action :set_group, only: [:show, :update, :destroy, :leave]
      before_action :authorize_group

      # GET /api/v1/groups
      def index
        @user = current_user
        @groups = policy_scope(Group)
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
    target_user = @user || current_user
    membership = @group.memberships.find_by(user: target_user)

    unless membership
      render json: { error: 'Membership not found' }, status: :not_found
      return
    end

    # Vérifier si c'est le dernier admin
    if membership.role == 'admin' && @group.admin_count == 1
      render json: { error: 'Cannot leave group: group must have at least one admin' }, status: :unprocessable_entity
      return
    end

    membership.destroy
    render json: { message: 'Successfully left the group' }, status: :ok
  end

      private

      def set_group
        @group = Group.find_by(id: params[:id])
        render json: { error: 'Group not found' }, status: :not_found unless @group
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

      def authorize_group
        case action_name
        when 'index', 'create'
          authorize Group
        when 'show', 'update', 'destroy'
          authorize @group
        when 'leave'
          authorize @group, :leave?
        end
      end
    end
  end
end
