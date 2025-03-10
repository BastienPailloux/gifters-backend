module Api
  module V1
    class GroupsController < BaseController
      before_action :authenticate_user!
      before_action :set_group, only: [:show, :update, :destroy, :join, :leave]
      before_action :ensure_member, only: [:show]
      before_action :ensure_member_for_update_destroy, only: [:update, :destroy]
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

      # POST /api/v1/groups
      def create
        @group = Group.new(group_params)

        if @group.save
          # Ajouter l'utilisateur actuel comme administrateur du groupe
          @group.add_user(current_user, 'admin')

          render json: @group, status: :created, only: [:id, :name, :description, :invite_code]
        else
          render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/groups/:id
      def update
        if @group.update(group_params)
          render json: @group, only: [:id, :name, :description, :invite_code]
        else
          render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:id
      def destroy
        @group.destroy
        head :no_content
      end

      # POST /api/v1/groups/:id/join
      def join
        # Vérifier si l'utilisateur est déjà membre du groupe
        if @group.users.include?(current_user)
          render json: { error: 'You are already a member of this group' }, status: :unprocessable_entity
          return
        end

        # Vérifier si le code d'invitation est valide
        if @group.invite_code == params[:invite_code]
          @group.add_user(current_user)
          render json: { message: 'Successfully joined the group' }, status: :ok
        else
          render json: { error: 'Invalid invite code' }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:id/leave
      def leave
        # Vérifier si l'utilisateur est membre du groupe
        unless @group.users.include?(current_user)
          render json: { error: 'You are not a member of this group' }, status: :unprocessable_entity
          return
        end

        # Vérifier si l'utilisateur est le dernier administrateur du groupe
        if @group.admin_users == [current_user]
          render json: { error: 'You cannot leave the group as you are the last admin' }, status: :unprocessable_entity
          return
        end

        # Supprimer l'utilisateur du groupe
        membership = @group.memberships.find_by(user: current_user)
        membership.destroy if membership

        render json: { message: 'Successfully left the group' }, status: :ok
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

      def ensure_member_for_update_destroy
        unless @group && @group.users.include?(current_user)
          render json: { error: 'You are not a member of this group' }, status: :forbidden
          return false
        end
        true
      end

      def ensure_admin
        return unless ensure_member_for_update_destroy

        unless @group.admin_users.include?(current_user)
          action = action_name == 'update' ? 'update' : 'delete'
          render json: { error: "You must be an admin to #{action} this group" }, status: :forbidden
        end
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end
    end
  end
end
