module Api
  module V1
    class ChildrenController < Api::V1::BaseController
      before_action :set_child, only: [:show, :update, :destroy]
      before_action :authorize_parent, only: [:show, :update, :destroy]

      # GET /api/v1/children
      def index
        @children = current_user.children
      end

      # GET /api/v1/children/:id

      # POST /api/v1/children
      def create
        @child = User.new(child_params)
        @child.account_type = 'managed'
        @child.parent_id = current_user.id

        if @child.save
          render :create, status: :created
        else
          render json: { errors: @child.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/children/:id
      def update
        if @child.update(child_params)
          render :update
        else
          render json: { errors: @child.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/children/:id
      def destroy
        @child.destroy
        render json: { message: 'Child account deleted successfully' }, status: :ok
      end

      private

      def set_child
        @child = User.find_by(id: params[:id])
        unless @child
          render json: { error: 'Child account not found' }, status: :not_found
        end
      end

      def authorize_parent
        unless @child && current_user.can_access_as_parent?(@child)
          render json: { error: 'Forbidden: You are not the parent of this account' }, status: :forbidden
        end
      end

      def child_params
        params.require(:user).permit(
          :name,
          :birthday,
          :gender,
          :phone_number,
          :address,
          :city,
          :state,
          :zip_code,
          :country
        )
      end
    end
  end
end
