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
  let(:gift_idea_for_another_user) { create(:gift_idea, created_by: user, for_user: another_user) }
  let(:gift_idea_for_user) { create(:gift_idea, created_by: another_user, for_user: user) }

  describe "GET /api/v1/gift_ideas" do
    context "when authenticated" do
      before do
        # Créer quelques idées de cadeaux
        gift_idea_for_another_user
        gift_idea_for_user
        create(:gift_idea, created_by: user, for_user: third_user)

        get "/api/v1/gift_ideas", headers: headers
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns only gift ideas visible to the user" do
        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        # L'utilisateur devrait voir les idées créées mais pas celles qui lui sont destinées
        expect(gift_ideas.size).to eq(2)
        expect(gift_ideas.map { |gi| gi['id'] }).to include(gift_idea_for_another_user.id)
        expect(gift_ideas.map { |gi| gi['id'] }).not_to include(gift_idea_for_user.id)
      end

      it "returns gift ideas with correct attributes" do
        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.first).to include('id', 'title', 'description', 'link', 'price', 'status')
        expect(gift_ideas.first).to include('created_by_id', 'for_user_id')
      end
    end

    context "with filter parameters" do
      before do
        # Créer un cadeau avec le statut "buying" et définir l'utilisateur courant comme acheteur
        @buying_gift = create(:gift_idea, created_by: user, for_user: another_user, status: 'buying', buyer: user)
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
        proposed_gift = create(:gift_idea, created_by: user, for_user: another_user, status: 'proposed')
        buying_gift = create(:gift_idea, created_by: user, for_user: another_user, status: 'buying', buyer: user)
        bought_gift = create(:gift_idea, created_by: user, for_user: another_user, status: 'bought', buyer: user)

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

      it "filters by for_user_id" do
        get "/api/v1/gift_ideas?for_user_id=#{another_user.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.all? { |gi| gi['for_user_id'] == another_user.id }).to be true
      end

      it "filters by group_id" do
        # Créer un autre groupe avec un autre utilisateur
        other_group = create(:group)
        other_user = create(:user)
        other_group.add_user(user)
        other_group.add_user(other_user)

        # Créer des idées de cadeaux pour les deux groupes
        gift_in_first_group = create(:gift_idea, created_by: user, for_user: another_user)

        # Vérifier le filtrage pour le premier groupe
        get "/api/v1/gift_ideas?group_id=#{group.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.map { |gi| gi['id'] }).to include(gift_in_first_group.id)

        # Créer un cadeau pour un utilisateur qui n'est pas dans le premier groupe
        # mais qui est dans le second groupe avec l'utilisateur courant
        gift_in_second_group = GiftIdea.new(
          title: "Gift for user in second group",
          description: "A gift for testing",
          link: "https://example.com/gift",
          price: 29.99,
          created_by: user,
          for_user: other_user
        )
        # Contourner la validation
        gift_in_second_group.save(validate: false)

        # Vérifier le filtrage pour le second groupe
        get "/api/v1/gift_ideas?group_id=#{other_group.id}", headers: headers

        gift_ideas = JSON.parse(response.body)["giftIdeas"]
        expect(gift_ideas.map { |gi| gi['id'] }).to include(gift_in_second_group.id)
        expect(gift_ideas.map { |gi| gi['id'] }).not_to include(gift_in_first_group.id)
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
          expect(JSON.parse(response.body)["giftIdea"]['id']).to eq(gift_idea_for_another_user.id)
        end

        it "returns gift idea with correct attributes" do
          gift_idea = JSON.parse(response.body)["giftIdea"]
          expect(gift_idea).to include('id', 'title', 'description', 'link', 'price', 'status')
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
          for_user_id: another_user.id
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
          for_user_id: another_user.id
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

      context "when the for_user is not in a common group with the creator" do
        let(:user_not_in_group) { create(:user) }
        let(:invalid_user_attributes) {
          {
            gift_idea: {
              title: "Gift for user not in group",
              description: "This should fail",
              link: "https://example.com/gift",
              price: 29.99,
              for_user_id: user_not_in_group.id
            }
          }
        }

        before { post "/api/v1/gift_ideas", params: invalid_user_attributes, headers: headers }

        it "returns status code 422" do
          expect(response).to have_http_status(422)
        end

        it "returns an error message about common group" do
          expect(JSON.parse(response.body)['errors']).to include(/must be in a common group/)
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
        let(:another_user_gift) { create(:gift_idea, created_by: another_user, for_user: user) }

        before { put "/api/v1/gift_ideas/#{another_user_gift.id}", params: valid_attributes, headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to update this gift idea')
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
        before { delete "/api/v1/gift_ideas/#{gift_idea_for_another_user.id}", headers: headers }

        it "returns status code 204" do
          expect(response).to have_http_status(204)
        end

        it "deletes the gift idea" do
          expect(GiftIdea.find_by(id: gift_idea_for_another_user.id)).to be_nil
        end
      end

      context "when trying to delete another user's gift idea" do
        let(:another_user_gift) { create(:gift_idea, created_by: another_user, for_user: user) }

        before { delete "/api/v1/gift_ideas/#{another_user_gift.id}", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to destroy this gift idea')
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
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to mark_as_buying this gift idea')
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
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to mark_as_bought this gift idea')
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
