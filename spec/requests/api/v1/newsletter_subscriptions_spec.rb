require 'rails_helper'

RSpec.describe "Api::V1::NewsletterSubscriptions", type: :request do
  # Ajouter un mock global pour ENV
  before do
    # Stub par défaut pour toutes les clés ENV
    allow(ENV).to receive(:[]).and_return(nil)
    # Configurations spécifiques
    allow(ENV).to receive(:[]).with('BREVO_LIST_ID').and_return('6')
    allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('http://localhost:5173')
    # Autres clés qui pourraient être utilisées
    allow(ENV).to receive(:[]).with('RAILS_CACHE_ID').and_return(nil)
  end

  describe "POST /api/v1/newsletter/subscribe" do
    let(:valid_email) { "test@example.com" }
    let(:valid_params) { { email: valid_email } }
    let(:invalid_email) { "invalid-email" }

    context "with valid email" do
      before do
        allow(BrevoService).to receive(:subscribe_contact).and_return({ success: true })
      end

      it "returns a success response" do
        post "/api/v1/newsletter/subscribe", params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('message')
      end

      it "calls BrevoService.subscribe_contact with correct parameters" do
        expect(BrevoService).to receive(:subscribe_contact).with(valid_email, '6', 'http://localhost:5173')
        post "/api/v1/newsletter/subscribe", params: valid_params
      end

      it "supports nested parameters format" do
        nested_params = { newsletter: { email: valid_email } }
        expect(BrevoService).to receive(:subscribe_contact).with(valid_email, '6', 'http://localhost:5173')
        post "/api/v1/newsletter/subscribe", params: nested_params
      end

      it "supports double nested parameters format" do
        double_nested_params = { newsletter_subscription: { newsletter: { email: valid_email } } }
        expect(BrevoService).to receive(:subscribe_contact).with(valid_email, '6', 'http://localhost:5173')
        post "/api/v1/newsletter/subscribe", params: double_nested_params
      end
    end

    context "with invalid email" do
      it "returns an unprocessable entity response" do
        post "/api/v1/newsletter/subscribe", params: { email: invalid_email }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context "when BrevoService returns an error" do
      before do
        allow(BrevoService).to receive(:subscribe_contact).and_return({ success: false, error: "API Error" })
      end

      it "returns an unprocessable entity response with the error message" do
        post "/api/v1/newsletter/subscribe", params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error' => "API Error")
      end
    end

    context "when an exception occurs" do
      before do
        allow(BrevoService).to receive(:subscribe_contact).and_raise(StandardError.new("Service Error"))
      end

      it "returns an internal server error response" do
        post "/api/v1/newsletter/subscribe", params: valid_params
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe "DELETE /api/v1/newsletter/unsubscribe" do
    let(:valid_email) { "test@example.com" }
    let(:invalid_email) { "invalid-email" }

    context "with valid email" do
      before do
        allow(BrevoService).to receive(:unsubscribe_contact).and_return({ success: true })
      end

      it "returns a success response" do
        delete "/api/v1/newsletter/unsubscribe", params: { email: valid_email }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('message')
      end

      it "calls BrevoService.unsubscribe_contact with correct parameters" do
        expect(BrevoService).to receive(:unsubscribe_contact).with(valid_email, nil)
        delete "/api/v1/newsletter/unsubscribe", params: { email: valid_email }
      end
    end

    context "with invalid email" do
      it "returns an unprocessable entity response" do
        delete "/api/v1/newsletter/unsubscribe", params: { email: invalid_email }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context "when BrevoService returns an error" do
      before do
        allow(BrevoService).to receive(:unsubscribe_contact).and_return({ success: false, error: "API Error" })
      end

      it "returns an unprocessable entity response with the error message" do
        delete "/api/v1/newsletter/unsubscribe", params: { email: valid_email }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error' => "API Error")
      end
    end

    context "when an exception occurs" do
      before do
        allow(BrevoService).to receive(:unsubscribe_contact).and_raise(StandardError.new("Service Error"))
      end

      it "returns an internal server error response" do
        delete "/api/v1/newsletter/unsubscribe", params: { email: valid_email }
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end
end
