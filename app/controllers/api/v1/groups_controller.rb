module Api
  module V1
    class GroupsController < Api::V1::BaseController
      before_action :set_group, only: [:show, :update, :destroy, :leave]
      before_action :ensure_member, only: [:show]
      before_action :ensure_member_for_update_destroy, only: [:update, :destroy]
      before_action :ensure_admin, only: [:update, :destroy]

      # GET /api/v1/groups
      def index
        @groups = current_user.groups || []

        # Utiliser to_json et éviter l'utilisation du serializer qui génère l'erreur
        if @groups.empty?
          render json: { groups: [] }, adapter: nil
          return
        end

        render json: @groups.map { |group|
          # S'assurer que group est valide avant d'appeler members_count
          if group.respond_to?(:members_count)
            group.as_json(only: [:id, :name, :description]).merge(members_count: group.members_count)
          else
            group.as_json(only: [:id, :name, :description]).merge(members_count: 0)
          end
        }
      end

      # GET /api/v1/groups/:id
      def show
        members = @group.users
        response_data = {
          id: @group.id,
          name: @group.name,
          description: @group.description,
          members_count: @group.members_count,
          members: @group.memberships.includes(:user).map { |m| m.user.as_json(only: [:id, :name, :email]).merge(role: m.role) }
        }

        render json: response_data
      end

      # POST /api/v1/groups
      def create
        @group = Group.new(group_params)

        if @group.save
          @group.memberships.create(user: current_user, role: 'admin')

          render json: @group.as_json(only: [:id, :name, :description]).merge(members_count: @group.members_count),
                 status: :created
        else
          render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/groups/:id
      def update
        if @group.update(group_params)
          render json: @group.as_json(only: [:id, :name, :description]).merge(members_count: @group.members_count)
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
