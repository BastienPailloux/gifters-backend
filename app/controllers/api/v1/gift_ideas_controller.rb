module Api
  module V1
    class GiftIdeasController < BaseController
      before_action :authenticate_user!
      before_action :set_gift_idea, only: [:show, :update, :destroy, :mark_as_buying, :mark_as_bought]
      before_action :authorize_access, only: [:show]
      before_action :authorize_modification, only: [:update, :destroy, :mark_as_buying, :mark_as_bought]

      # GET /api/v1/gift_ideas
      def index
        # Utiliser le scope principal pour récupérer les idées visibles par l'utilisateur
        @gift_ideas = GiftIdea.visible_to_user(current_user)

        # Appliquer les filtres si nécessaire
        @gift_ideas = case params[:status]
                      when 'proposed'
                        @gift_ideas.proposed
                      when 'buying'
                        @gift_ideas.buying
                      when 'bought'
                        @gift_ideas.bought
                      else
                        @gift_ideas
                      end

        @gift_ideas = @gift_ideas.for_recipient(params[:for_user_id]) if params[:for_user_id].present?

        render json: @gift_ideas
      end

      # GET /api/v1/gift_ideas/:id
      def show
        render json: @gift_idea
      end

      # POST /api/v1/gift_ideas
      def create
        @gift_idea = GiftIdea.new(gift_idea_params)
        @gift_idea.created_by = current_user

        if @gift_idea.save
          render json: @gift_idea, status: :created
        else
          render json: { errors: @gift_idea.errors.full_messages }, status: :unprocessable_entity
        end
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
