require 'rails_helper'

RSpec.describe "Api::V1::GiftIdeas", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  # Création d'un groupe et ajout de l'utilisateur
  let(:group) { create(:group) }
  let(:another_user) { create(:user) }

  before do
    group.add_user(user)
    group.add_user(another_user)
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
        create(:gift_idea, created_by: user, for_user: create(:user))

        get "/api/v1/gift_ideas", headers: headers
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns only gift ideas visible to the user" do
        gift_ideas = JSON.parse(response.body)
        # L'utilisateur devrait voir les idées créées mais pas celles qui lui sont destinées
        expect(gift_ideas.size).to eq(2)
        expect(gift_ideas.map { |gi| gi['id'] }).to include(gift_idea_for_another_user.id)
        expect(gift_ideas.map { |gi| gi['id'] }).not_to include(gift_idea_for_user.id)
      end

      it "returns gift ideas with correct attributes" do
        gift_ideas = JSON.parse(response.body)
        expect(gift_ideas.first).to include('id', 'title', 'description', 'link', 'price', 'status')
        expect(gift_ideas.first).to include('created_by_id', 'for_user_id')
      end
    end

    context "with filter parameters" do
      before do
        gift_idea_for_another_user
        gift_idea_for_user

        # Créer une idée avec statut "buying"
        buying_idea = create(:gift_idea, created_by: user, for_user: another_user, status: 'buying')

        # Créer une idée avec statut "bought"
        bought_idea = create(:gift_idea, created_by: user, for_user: another_user, status: 'bought')
      end

      it "filters by status" do
        get "/api/v1/gift_ideas?status=buying", headers: headers
        gift_ideas = JSON.parse(response.body)
        expect(gift_ideas.size).to eq(1)
        expect(gift_ideas.first['status']).to eq('buying')
      end

      it "filters by for_user_id" do
        get "/api/v1/gift_ideas?for_user_id=#{another_user.id}", headers: headers
        gift_ideas = JSON.parse(response.body)
        expect(gift_ideas.all? { |gi| gi['for_user_id'] == another_user.id }).to be true
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
          expect(JSON.parse(response.body)['id']).to eq(gift_idea_for_another_user.id)
        end

        it "returns gift idea with correct attributes" do
          gift_idea = JSON.parse(response.body)
          expect(gift_idea).to include('id', 'title', 'description', 'link', 'price', 'status')
          expect(gift_idea).to include('created_by_id', 'for_user_id')
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
          expect(JSON.parse(response.body)['title']).to eq("New Gift Idea")
        end

        it "sets the created_by_id to the current user" do
          expect(JSON.parse(response.body)['created_by_id']).to eq(user.id)
        end

        it "sets the default status to 'proposed'" do
          expect(JSON.parse(response.body)['status']).to eq('proposed')
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
          expect(JSON.parse(response.body)['title']).to eq("Updated Gift Idea")
          expect(JSON.parse(response.body)['price']).to eq(39.99)
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
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to delete this gift idea')
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
          expect(JSON.parse(response.body)['status']).to eq('buying')
        end
      end

      context "when the gift idea is not visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_user.id}/mark_as_buying", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to update this gift idea')
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
          expect(JSON.parse(response.body)['status']).to eq('bought')
        end
      end

      context "when the gift idea is not visible to the user" do
        before { put "/api/v1/gift_ideas/#{gift_idea_for_user.id}/mark_as_bought", headers: headers }

        it "returns status code 403" do
          expect(response).to have_http_status(403)
        end

        it "returns a forbidden message" do
          expect(JSON.parse(response.body)).to include('error' => 'You are not authorized to update this gift idea')
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
