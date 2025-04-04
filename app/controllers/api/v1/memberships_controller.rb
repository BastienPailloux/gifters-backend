module Api
  module V1
    class MembershipsController < Api::V1::BaseController
      before_action :set_group
      before_action :ensure_user_in_group, except: [:create]
      before_action :set_membership, only: [:show, :update, :destroy]
      before_action :ensure_admin, only: [:create]
      before_action :ensure_admin, only: [:update], unless: :updating_own_membership?
      before_action :ensure_admin, only: [:destroy], unless: :deleting_own_membership?

      # GET /api/v1/groups/:group_id/memberships
      def index
        @memberships = @group.memberships.includes(:user)
        render json: @memberships.as_json(include: { user: { only: [:id, :name, :email] } },
                                         methods: [:user_name, :user_email])
      end

      # GET /api/v1/groups/:group_id/memberships/:id
      def show
        render json: @membership.as_json(include: { user: { only: [:id, :name, :email] } },
                                        methods: [:user_name, :user_email])
      end

      # POST /api/v1/groups/:group_id/memberships
      def create
        # Vérifier si l'utilisateur est membre du groupe avant de créer un nouveau membership
        if !current_user_membership
          render json: { error: 'You are not a member of this group' }, status: :forbidden
          return
        end

        # Vérifier si l'utilisateur est admin
        unless current_user_membership.admin?
          render json: { error: 'You must be an admin to add members to this group' }, status: :forbidden
          return
        end

        @membership = @group.memberships.new(membership_params)

        if @membership.save
          render json: @membership.as_json(include: { user: { only: [:id, :name, :email] } },
                                          methods: [:user_name, :user_email]),
                 status: :created
        else
          render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/groups/:group_id/memberships/:id
      def update
        # Vérifier si l'utilisateur est admin ou s'il modifie son propre membership
        unless current_user_membership.admin? || updating_own_membership?
          render json: { error: 'You must be an admin to update memberships in this group' }, status: :forbidden
          return
        end

        # Vérifier si c'est le dernier admin
        if @membership.role == 'admin' && membership_params[:role] == 'member' && @group.admin_count == 1
          render json: { errors: ['Cannot change role: group must have at least one admin'] }, status: :unprocessable_entity
          return
        end

        # Si l'utilisateur essaie de changer son propre rôle, vérifier qu'il y a au moins un autre admin
        if updating_own_membership? && @membership.role == 'admin' && membership_params[:role] == 'member'
          # Compter le nombre d'admins autres que l'utilisateur actuel
          other_admins_count = @group.memberships.where(role: 'admin').where.not(user_id: current_user.id).count

          if other_admins_count == 0
            render json: { errors: ['Cannot change role: group must have at least one admin'] }, status: :unprocessable_entity
            return
          end
        end

        if @membership.update(membership_params)
          render json: @membership.as_json(include: { user: { only: [:id, :name, :email] } },
                                          methods: [:user_name, :user_email])
        else
          render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:group_id/memberships/:id
      def destroy
        # Vérifier si l'utilisateur est admin ou s'il supprime son propre membership
        unless current_user_membership.admin? || deleting_own_membership?
          render json: { error: 'You must be an admin to remove members from this group' }, status: :forbidden
          return
        end

        # Vérifier si c'est le dernier admin
        if @membership.role == 'admin' && @group.admin_count == 1
          render json: { errors: ['Cannot delete membership: group must have at least one admin'] }, status: :unprocessable_entity
          return
        end

        @membership.destroy
        head :no_content
      end

      private

      def set_group
        @group = Group.find_by(id: params[:group_id])

        unless @group
          render json: { error: 'Group not found' }, status: :not_found
          return
        end
      end

      def set_membership
        @membership = @group.memberships.find_by(id: params[:id])

        unless @membership
          render json: { error: 'Membership not found' }, status: :not_found
        end
      end

      def ensure_user_in_group
        unless current_user_membership
          render json: { error: 'You are not a member of this group' }, status: :forbidden
        end
      end

      def ensure_admin
        unless current_user_membership&.admin?
          action_name = params[:action] == 'create' ? 'add members to' :
                        params[:action] == 'update' ? 'update memberships in' :
                        'remove members from'
          render json: { error: "You must be an admin to #{action_name} this group" }, status: :forbidden
        end
      end

      def current_user_membership
        @current_user_membership ||= @group.memberships.find_by(user: current_user)
      end

      def updating_own_membership?
        @membership&.user_id == current_user.id
      end

      def deleting_own_membership?
        @membership&.user_id == current_user.id
      end

      def membership_params
        params.require(:membership).permit(:user_id, :role)
      end
    end
  end
end
