require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let(:user) { create(:user) }

  describe "PATCH #update_locale" do
    context "when user is authorized to update their own locale" do
      before do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "updates the user's locale" do
        patch :update_locale, params: { id: user.id, user: { locale: 'fr' } }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"]["locale"]).to eq('fr')
        expect(user.reload.locale).to eq('fr')
      end
    end

    context "when user tries to update another user's locale" do
      let(:other_user) { create(:user) }

      before do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "returns a forbidden status" do
        patch :update_locale, params: { id: other_user.id, user: { locale: 'fr' } }

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["status"]["message"]).to match(/Not authorized/)
      end
    end
  end
end
