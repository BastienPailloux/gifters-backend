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

        # Appliquer les filtres par statut si nécessaire
        if params[:status].present?
          # Convertir le paramètre en tableau (s'il ne l'est pas déjà)
          statuses = params[:status].is_a?(Array) ? params[:status] : [params[:status]].flatten

          if statuses.present?
            # Initialiser une requête vide
            status_query = nil

            # Construire la requête pour chaque statut demandé
            statuses.each do |status|
              sub_query = case status.to_s
              when 'proposed'
                @gift_ideas.proposed
              when 'buying'
                @gift_ideas.buying
              when 'bought'
                @gift_ideas.bought
              else
                nil
              end

              if sub_query
                status_query = status_query ? status_query.or(sub_query) : sub_query
              end
            end

            # Appliquer la requête combinée si elle a été construite
            @gift_ideas = status_query if status_query
          end
        end

        # Ajouter des filtres pour limiter par utilisateur destinataire si demandé
        if params[:for_user_id].present?
          # Pour la compatibilité avec l'ancien format
          @gift_ideas = @gift_ideas.for_recipient(params[:for_user_id])
        elsif params[:recipient_id].present?
          @gift_ideas = @gift_ideas.for_recipient(params[:recipient_id])
        end

        # Ajouter un filtre pour limiter par créateur si demandé
        if params[:created_by_id].present?
          @gift_ideas = @gift_ideas.where(created_by_id: params[:created_by_id])
        end

        # Ajouter un filtre pour limiter par groupe si demandé
        if params[:group_id].present?
          group = Group.find_by(id: params[:group_id])
          if group && group.users.include?(current_user)
            @gift_ideas = @gift_ideas.for_group(params[:group_id])
          else
            # Si le groupe n'existe pas ou si l'utilisateur n'en est pas membre, retourner une liste vide
            @gift_ideas = GiftIdea.none
          end
        end

        # Ajouter un filtre pour limiter par acheteur (buyer_id) si demandé
        @gift_ideas = @gift_ideas.with_buyer(params[:buyer_id]) if params[:buyer_id].present?

        # Exclure les idées cadeaux dont l'utilisateur courant est destinataire si demandé
        if params[:exclude_own_wishlist].present? && params[:exclude_own_wishlist] == 'true'
          @gift_ideas = @gift_ideas.not_for_user(current_user)
        end

        # Inclure les associations pour le sérialiseur
        @gift_ideas = @gift_ideas.includes(:recipients, :created_by)

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

        # Traiter les destinataires
        if params[:gift_idea][:recipient_ids].present?
          recipient_ids = params[:gift_idea][:recipient_ids]
          recipient_ids = [recipient_ids] unless recipient_ids.is_a?(Array)

          # Vérifier que tous les utilisateurs existent
          recipients = User.where(id: recipient_ids)
          if recipients.count != recipient_ids.uniq.count
            return render json: { errors: ["Some recipient users don't exist"] }, status: :unprocessable_entity
          end

          # Associer les destinataires
          @gift_idea.recipients = recipients
        end

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
        if @gift_idea.is_recipient?(current_user)
          render json: { error: "You cannot change the status of your own gift" }, status: :forbidden
          return false
        end

        true
      end

      def gift_idea_params
        params.require(:gift_idea).permit(:title, :description, :link, :price, :image_url, recipient_ids: [])
      end
    end
  end
end
