module Api
  module V1
    class GiftIdeasController < Api::V1::BaseController
      before_action :set_gift_idea, only: [:show, :update, :destroy, :mark_as_buying, :mark_as_bought]
      before_action :authorize_access, only: [:show]
      before_action :authorize_modification, only: [:update, :destroy]
      before_action :authorize_status_change, only: [:mark_as_buying, :mark_as_bought]

      # GET /api/v1/gift_ideas
      def index
        # Utiliser le scope principal pour récupérer les idées visibles par l'utilisateur
        @gift_ideas = GiftIdea.visible_to_user(current_user)

        # Appliquer les filtres si nécessaire
        @gift_ideas = case params[:status]
                      when 'proposed'
                        @gift_ideas.proposed
                      when 'buying'
                        # Si le statut est 'buying', ne montrer que les cadeaux où l'utilisateur actuel est l'acheteur
                        @gift_ideas.buying.where(buyer_id: current_user.id)
                      when 'bought'
                        @gift_ideas.bought.where(buyer_id: current_user.id)
                      else
                        @gift_ideas
                      end

        # Ajouter des filtres pour limiter par utilisateur si demandé
        @gift_ideas = @gift_ideas.for_recipient(params[:for_user_id]) if params[:for_user_id].present?

        # Inclure les associations pour le sérialiseur
        @gift_ideas = @gift_ideas.includes(:for_user, :created_by)

        # Sérialiser chaque idée de cadeau individuellement pour s'assurer que tous les attributs sont inclus
        serialized_gift_ideas = @gift_ideas.map do |gift|
          GiftIdeaSerializer.new(gift, scope: current_user).as_json
        end

        # Retourner les données sérialisées
        render json: { giftIdeas: serialized_gift_ideas }
      end

      # GET /api/v1/gift_ideas/:id
      def show
        render json: { giftIdea: GiftIdeaSerializer.new(@gift_idea, scope: current_user).as_json }
      end

      # POST /api/v1/gift_ideas
      def create
        @gift_idea = GiftIdea.new(gift_idea_params)
        # Assigner l'utilisateur courant comme créateur
        @gift_idea.created_by = current_user

        if @gift_idea.save
          render json: { giftIdea: GiftIdeaSerializer.new(@gift_idea, scope: current_user).as_json }, status: :created
        else
          render json: { errors: @gift_idea.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/gift_ideas/:id
      def update
        if @gift_idea.update(gift_idea_params)
          render json: { giftIdea: GiftIdeaSerializer.new(@gift_idea, scope: current_user).as_json }
        else
          render json: { errors: @gift_idea.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/gift_ideas/:id
      def destroy
        @gift_idea.destroy
        head :no_content
      end

      # PUT /api/v1/gift_ideas/:id/mark_as_buying
      def mark_as_buying
        if @gift_idea.mark_as_buying(current_user)
          render json: { giftIdea: GiftIdeaSerializer.new(@gift_idea, scope: current_user).as_json }
        else
          render json: { errors: @gift_idea.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/gift_ideas/:id/mark_as_bought
      def mark_as_bought
        if @gift_idea.mark_as_bought(current_user)
          render json: { giftIdea: GiftIdeaSerializer.new(@gift_idea, scope: current_user).as_json }
        else
          render json: { errors: @gift_idea.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_gift_idea
        @gift_idea = GiftIdea.find_by(id: params[:id])
        unless @gift_idea
          render json: { error: "Gift idea not found" }, status: :not_found
          return false
        end
      end

      def authorize_access
        unless @gift_idea.visible_to?(current_user)
          render json: { error: "You are not authorized to view this gift idea" }, status: :forbidden
          return false
        end
        true
      end

      def authorize_modification
        # Vérifier d'abord si l'utilisateur peut voir l'idée de cadeau
        unless @gift_idea.visible_to?(current_user)
          render json: { error: "You are not authorized to #{action_name} this gift idea" }, status: :forbidden
          return false
        end

        # Ensuite, vérifier si l'utilisateur est le créateur
        unless @gift_idea.created_by == current_user
          render json: { error: "You are not authorized to #{action_name} this gift idea" }, status: :forbidden
          return false
        end

        true
      end

      # Nouvelle méthode pour autoriser les changements de statut (buying/bought)
      def authorize_status_change
        # Pour les changements de statut, il suffit que l'utilisateur puisse voir le cadeau
        # Cela permet à n'importe quel membre du groupe de marquer un cadeau comme "en cours d'achat" ou "acheté"
        unless @gift_idea.visible_to?(current_user)
          render json: { error: "You are not authorized to #{action_name} this gift idea" }, status: :forbidden
          return false
        end

        # Ne pas autoriser le destinataire du cadeau à changer son statut
        if @gift_idea.for_user_id == current_user.id
          render json: { error: "You cannot change the status of your own gift" }, status: :forbidden
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
