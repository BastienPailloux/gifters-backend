module Api
  module V1
    class MembershipsController < Api::V1::BaseController
      before_action :set_group
      before_action :set_membership, only: [:show, :update, :destroy]
      before_action :authorize_membership

      # GET /api/v1/groups/:group_id/memberships
      def index
        @memberships = policy_scope(@group.memberships).includes(:user)
        render json: @memberships, each_serializer: MembershipSerializer
      end

      # GET /api/v1/groups/:group_id/memberships/:id
      def show
        render json: @membership, serializer: MembershipSerializer
      end

      # POST /api/v1/groups/:group_id/memberships
      def create
        @membership = @group.memberships.new(membership_params)

        if @membership.save
          render json: @membership, serializer: MembershipSerializer, status: :created
        else
          render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/groups/:group_id/memberships/:id
      def update
        # Vérifier si c'est le dernier admin
        if @membership.role == 'admin' && membership_params[:role] == 'member' && @group.admin_count == 1
          render json: { errors: ['Cannot change role: group must have at least one admin'] }, status: :unprocessable_entity
          return
        end

        if @membership.update(membership_params)
          render json: @membership, serializer: MembershipSerializer
        else
          render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/groups/:group_id/memberships/:id
      def destroy
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

      def membership_params
        params.require(:membership).permit(:user_id, :role)
      end

      def authorize_membership
        case action_name
        when 'index'
          # Pour index, on vérifie si l'user peut voir les memberships du groupe
          authorize @group, :show_memberships?
        when 'create'
          authorize @group, :manage_memberships?
        when 'show', 'update', 'destroy'
          authorize @membership
        end
      end
    end
  end
end
