module Api
  module V1
    class GiftIdeasController < BaseController
      before_action :authenticate_user!
      before_action :set_gift_idea, only: [:show, :update, :destroy, :mark_as_buying, :mark_as_bought]
      before_action :authorize_access, only: [:show]
      before_action :authorize_modification, only: [:update, :destroy, :mark_as_buying, :mark_as_bought]

      # GET /api/v1/gift_ideas
      def index
        # Récupérer les idées de cadeaux visibles pour l'utilisateur actuel
        # Un utilisateur peut voir les idées qu'il a créées, mais pas celles qui lui sont destinées
        @gift_ideas = GiftIdea.where(created_by: current_user)
                             .or(GiftIdea.where.not(for_user: current_user)
                                         .where(for_user_id: current_user.common_groups_with_users_ids))

        # Filtrer par statut si spécifié
        @gift_ideas = @gift_ideas.where(status: params[:status]) if params[:status].present?

        # Filtrer par destinataire si spécifié
        @gift_ideas = @gift_ideas.where(for_user_id: params[:for_user_id]) if params[:for_user_id].present?

        render json: @gift_ideas
      end

      # GET /api/v1/gift_ideas/:id
      def show
        render json: @gift_idea
      end

      private

      def set_gift_idea
        @gift_idea = GiftIdea.find_by(id: params[:id])
        unless @gift_idea
          render json: { error: 'Gift idea not found' }, status: :not_found
          return
        end
      end

      def authorize_access
        unless @gift_idea.visible_to?(current_user)
          render json: { error: 'You are not authorized to view this gift idea' }, status: :forbidden
          return false
        end
        true
      end

      def authorize_modification
        return false unless authorize_access

        unless @gift_idea.created_by == current_user
          render json: { error: 'You are not authorized to update this gift idea' }, status: :forbidden
          return false
        end
        true
      end

      def gift_idea_params
        params.require(:gift_idea).permit(:title, :description, :link, :price, :for_user_id)
      end
    end
  end
end
