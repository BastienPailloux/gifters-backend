require 'rails_helper'

RSpec.describe "Api::V1::Contacts", type: :request do
  describe "POST /api/v1/contact" do
    context "with valid parameters" do
      let(:valid_params) { { name: "Test User", email: "test@example.com", subject: "Test Subject", message: "This is a test message" } }

      it "sends an email" do
        expect {
          post "/api/v1/contact", params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "returns a success response" do
        post "/api/v1/contact", params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('status' => hash_including('message' => 'Message sent successfully'))
      end

      it "sends an email with the correct information" do
        post "/api/v1/contact", params: valid_params

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include('contact@gifters.fr')
        expect(email.subject).to eq("Contact Form: #{valid_params[:subject]}")
        expect(email.body.encoded).to include(valid_params[:name])
        expect(email.body.encoded).to include(valid_params[:email])
        expect(email.body.encoded).to include(valid_params[:message])
      end
    end

    context "with missing parameters" do
      it "returns an error for missing name" do
        post "/api/v1/contact", params: { email: "test@example.com", message: "Test message" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end

      it "returns an error for missing email" do
        post "/api/v1/contact", params: { name: "Test User", message: "Test message" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end

      it "returns an error for missing message" do
        post "/api/v1/contact", params: { name: "Test User", email: "test@example.com" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end

    context "when email delivery fails" do
      before do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(StandardError.new("Delivery failed"))
      end

      it "returns an internal server error" do
        post "/api/v1/contact", params: { name: "Test User", email: "test@example.com", subject: "Test", message: "Test message" }
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to include('status' => hash_including('message' => 'Failed to send message'))
      end
    end
  end
end
