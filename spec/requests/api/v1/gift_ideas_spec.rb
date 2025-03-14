require 'rails_helper'

RSpec.describe "Api::V1::GiftIdeas", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  # Création d'un groupe et ajout de l'utilisateur
  let(:group) { create(:group) }
  let(:another_user) { create(:user) }
  let(:third_user) { create(:user) }

  before do
    group.add_user(user)
    group.add_user(another_user)
    group.add_user(third_user)
  end

  # Création d'idées de cadeaux pour les tests
  let(:gift_idea_for_another_user) do
    gift = create(:gift_idea, created_by: user)
    gift.recipients << another_user
    gift
  end

  let(:gift_idea_for_user) do
    gift = create(:gift_idea, created_by: another_user)
    gift.recipients << user
    gift
  end

  describe "GET /api/v1/gift_ideas" do
    context "when authenticated" do
      before do
        # Créer quelques idées de cadeaux
        gift_idea_for_another_user
        gift_idea_for_user
        gift_for_third = create(:gift_idea, created_by: user)
        gift_for_third.recipients << third_user

        get "/api/v1/gift_ideas", headers: headers
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns only gift ideas visible to the user" do
        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        # L'utilisateur devrait voir les idées créées mais pas celles qui lui sont destinées
        expect(gift_ideas.size).to eq(2)
        expect(gift_ideas.map { |gi| gi['id'].to_i }).to include(gift_idea_for_another_user.id)
        expect(gift_ideas.map { |gi| gi['id'].to_i }).not_to include(gift_idea_for_user.id)
      end

      it "returns gift ideas with correct attributes" do
        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.first).to include('id', 'title', 'description', 'link', 'price', 'status')
        expect(gift_ideas.first).to include('created_by_id')
        expect(gift_ideas.first).to include('recipients')
      end
    end

    context "with filter parameters" do
      before do
        # Créer un cadeau avec le statut "buying" et définir l'utilisateur courant comme acheteur
        @buying_gift = create(:gift_idea, created_by: user, status: 'buying', buyer: user)
        @buying_gift.recipients << another_user
      end

      it "filters by status" do
        get "/api/v1/gift_ideas?status=buying", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to eq(1)
        expect(gift_ideas.first['status']).to eq('buying')
      end

      it "filters by multiple statuses" do
        # Supprimer toutes les idées de cadeaux existantes pour ce test
        GiftIdea.destroy_all

        # Créer des cadeaux avec différents statuts
        proposed_gift = create(:gift_idea, created_by: user, status: 'proposed')
        proposed_gift.recipients << another_user

        buying_gift = create(:gift_idea, created_by: user, status: 'buying', buyer: user)
        buying_gift.recipients << another_user

        bought_gift = create(:gift_idea, created_by: user, status: 'bought', buyer: user)
        bought_gift.recipients << another_user

        # Vérifier le filtrage pour plusieurs statuts
        get "/api/v1/gift_ideas?status[]=proposed&status[]=buying", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to eq(2)
        statuses = gift_ideas.map { |gi| gi['status'] }
        expect(statuses).to include('proposed')
        expect(statuses).to include('buying')
        expect(statuses).not_to include('bought')

        # Test avec un seul statut pour confirmer
        get "/api/v1/gift_ideas?status[]=proposed", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to eq(1)
        expect(gift_ideas.first['status']).to eq('proposed')
      end

      it "filters by recipient_id" do
        get "/api/v1/gift_ideas?recipient_id=#{another_user.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to be >= 1
        # Vérifier que tous les cadeaux ont le destinataire spécifié
        gift_ideas.each do |gi|
          recipient_ids = gi['recipients'].map { |r| r['id'].to_i }
          expect(recipient_ids).to include(another_user.id)
        end
      end

      it "filters by group_id" do
        # Créer un autre groupe avec un autre utilisateur
        other_group = create(:group)
        other_user = create(:user)
        other_group.add_user(user)
        other_group.add_user(other_user)

        # Créer des idées de cadeaux pour les deux groupes
        # 1. Cadeau pour un utilisateur dans le premier groupe
        gift_in_first_group = create(:gift_idea, created_by: user)
        gift_in_first_group.recipients.destroy_all  # Supprimer les destinataires par défaut
        gift_in_first_group.recipients << another_user
        gift_in_first_group.save!

        # Assurons-nous que les associations ont fonctionné
        expect(gift_in_first_group.recipients).to include(another_user)

        # Vérifier le filtrage pour le premier groupe
        get "/api/v1/gift_ideas?group_id=#{group.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        gift_idea_ids = gift_ideas.map { |gi| gi['id'].to_i }
        expect(gift_idea_ids).to include(gift_in_first_group.id)

        # 2. Cadeau pour un utilisateur dans le second groupe
        gift_in_second_group = create(:gift_idea, created_by: user)
        gift_in_second_group.recipients.destroy_all  # Supprimer les destinataires par défaut
        gift_in_second_group.recipients << other_user
        gift_in_second_group.save!

        # Vérifier le filtrage pour le second groupe
        get "/api/v1/gift_ideas?group_id=#{other_group.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        gift_idea_ids = gift_ideas.map { |gi| gi['id'].to_i }
        expect(gift_idea_ids).to include(gift_in_second_group.id)
        expect(gift_idea_ids).not_to include(gift_in_first_group.id)
      end

      it "returns empty array for non-existent group" do
        get "/api/v1/gift_ideas?group_id=999", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas).to be_empty
      end

      it "returns empty array for group user is not a member of" do
        # Créer un groupe dont l'utilisateur n'est pas membre
        non_member_group = create(:group)

        get "/api/v1/gift_ideas?group_id=#{non_member_group.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas).to be_empty
      end

      it "filters by buyer_id" do
        # Supprimer toutes les idées de cadeaux existantes pour ce test
        GiftIdea.destroy_all

        # Créer différents cadeaux avec différents acheteurs
        user_gift = create(:gift_idea, created_by: user, status: 'buying', buyer: user)
        user_gift.recipients << another_user

        another_user_gift = create(:gift_idea, created_by: user, status: 'buying', buyer: another_user)
        another_user_gift.recipients << third_user

        third_user_gift = create(:gift_idea, created_by: user, status: 'buying', buyer: third_user)
        third_user_gift.recipients << another_user

        # Vérifier le filtrage par buyer_id
        get "/api/v1/gift_ideas?buyer_id=#{user.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to eq(1)
        expect(gift_ideas.first['id'].to_i).to eq(user_gift.id)

        # Vérifier avec un autre acheteur
        get "/api/v1/gift_ideas?buyer_id=#{another_user.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.size).to eq(1)
        expect(gift_ideas.first['id'].to_i).to eq(another_user_gift.id)

        # Vérifier avec un acheteur qui n'existe pas
        get "/api/v1/gift_ideas?buyer_id=999", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas).to be_empty
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/gift_ideas" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "GET /api/v1/gift_ideas/:id" do
    context "when authenticated" do
      context "when the gift idea is visible to the user" do
        before { get "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "returns the gift idea" do
          expect(JSON.parse(response.body)["giftIdea"]['id'].to_i).to eq(gift_idea_for_another_user.id)
        end

        it "returns gift idea with correct attributes" do
          gift_idea = JSON.parse(response.body)["giftIdea"]
          expect(gift_idea).to include('id', 'title', 'description', 'link', 'price', 'status')
          expect(gift_idea).to include('recipients')
        end
      end

      context "when the gift idea is not visible to the user" do
        before { get "/api/v1/gift_ideas/#{gift_idea_for_user.id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to view this gift idea')
        end
      end

      context "when the gift idea does not exist" do
        before { get "/api/v1/gift_ideas/999", headers: headers }

        it "returns status code 404" do
          expect(response).to have_http_status(404)
        end

        it "returns a not found message" do
          expect(JSON.parse(response.body)).to include('error' => 'Gift idea not found')
        end
      end
    end

    context "when not authenticated" do
      before { get "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "POST /api/v1/gift_ideas" do
    let(:valid_attributes) {
      {
        gift_idea: {
          title: "New Gift Idea",
          description: "A great gift idea",
          link: "https://example.com/gift",
          price: 29.99,
          recipient_ids: [another_user.id]
        }
      }
    }

    let(:invalid_attributes) {
      {
        gift_idea: {
          title: "",
          description: "Invalid gift idea",
          link: "not-a-url",
          price: -10,
          recipient_ids: [another_user.id]
        }
      }
    }

    context "when authenticated" do
      context "when the request is valid" do
        before { post "/api/v1/gift_ideas", params: valid_attributes, headers: headers }

        it "returns status code 201" do
          expect(response).to have_http_status(201)
        end

        it "creates a new gift idea" do
          expect(JSON.parse(response.body)["giftIdea"]['title']).to eq("New Gift Idea")
        end

        it "sets the created_by_id to the current user" do
          expect(JSON.parse(response.body)["giftIdea"]['created_by_id']).to eq(user.id)
        end

        it "sets the default status to 'proposed'" do
          expect(JSON.parse(response.body)["giftIdea"]['status']).to eq('proposed')
        end

        it "adds the specified recipients" do
          recipients = JSON.parse(response.body)["giftIdea"]['recipients']
          expect(recipients.size).to eq(1)
          expect(recipients.first['id'].to_i).to eq(another_user.id)
        end
      end

      context "when the request is invalid" do
        before { post "/api/v1/gift_ideas", params: invalid_attributes, headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns a validation failure message" do
          expect(JSON.parse(response.body)).to include('errors')
        end
      end

      context "when no recipients are specified" do
        before do
          post "/api/v1/gift_ideas", params: {
            gift_idea: {
              title: "New Gift Idea",
              description: "A great gift idea",
              link: "https://example.com/gift",
              price: 29.99
            }
          }, headers: headers
        end

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message about recipients" do
          expect(JSON.parse(response.body)['errors']).to include("Gift idea must have at least one recipient")
        end
      end

      context "when a recipient is not in a common group with the creator" do
        let(:outside_user) { create(:user) }

        before do
          post "/api/v1/gift_ideas", params: {
            gift_idea: {
              title: "New Gift Idea",
              description: "A great gift idea",
              link: "https://example.com/gift",
              price: 29.99,
              recipient_ids: [outside_user.id]
            }
          }, headers: headers
        end

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message about common group" do
          expect(JSON.parse(response.body)['errors']).to include(/must all be in a common group with you/)
        end
      end
    end

    context "when not authenticated" do
      before { post "/api/v1/gift_ideas", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/gift_ideas/:id" do
    let(:valid_attributes) { { gift_idea: { title: "Updated Gift Idea", price: 39.99 } } }

    context "when authenticated" do
      context "when updating own gift idea" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}", params: valid_attributes, headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "updates the gift idea" do
          expect(JSON.parse(response.body)["giftIdea"]['title']).to eq("Updated Gift Idea")
          expect(JSON.parse(response.body)["giftIdea"]['price'].to_f).to eq(39.99)
        end
      end

      context "when trying to update another user's gift idea" do
        let(:another_user_gift) do
          gift = create(:gift_idea, created_by: another_user)
          gift.recipients << user
          gift
        end

        before { put "/api/v1/gift_ideas/#{another_user_gift.id}", params: valid_attributes, headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)['error']).to include("You are not authorized")
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}", params: valid_attributes }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "DELETE /api/v1/gift_ideas/:id" do
    context "when authenticated" do
      context "when deleting own gift idea" do
        let(:gift_to_delete) do
          gift = create(:gift_idea, created_by: user)
          gift.recipients << another_user
          gift
        end

        before { delete "/api/v1/gift_ideas/#{gift_to_delete.id}", headers: headers }

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the gift idea" do
          expect(GiftIdea.find_by(id: gift_to_delete.id)).to be_nil
        end
      end

      context "when trying to delete another user's gift idea" do
        let(:another_user_gift) do
          gift = create(:gift_idea, created_by: another_user)
          gift.recipients << user
          gift
        end

        before { delete "/api/v1/gift_ideas/#{another_user_gift.id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)['error']).to include("You are not authorized")
        end
      end
    end

    context "when not authenticated" do
      before { delete "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/gift_ideas/:id/mark_as_buying" do
    context "when authenticated" do
      context "when the gift idea is visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}/mark_as_buying", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "updates the status to 'buying'" do
          expect(JSON.parse(response.body)["giftIdea"]['status']).to eq('buying')
        end
      end

      context "when the gift idea is not visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_user.id}/mark_as_buying", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)['error']).to include("You are not authorized")
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}/mark_as_buying" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/gift_ideas/:id/mark_as_bought" do
    context "when authenticated" do
      context "when the gift idea is visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}/mark_as_bought", headers: headers }

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end

        it "updates the status to 'bought'" do
          expect(JSON.parse(response.body)["giftIdea"]['status']).to eq('bought')
        end
      end

      context "when the gift idea is not visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_user.id}/mark_as_bought", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)['error']).to include("You are not authorized")
        end
      end
    end

    context "when not authenticated" do
      before { put "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}/mark_as_bought" }

      it "returns status code 401" do
        expect(response).to have_http_status(401)
      end

      it "returns an unauthorized message" do
        expect(JSON.parse(response.body)).to include('error' => 'Unauthorized')
      end
    end
  end
end
