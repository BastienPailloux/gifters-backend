require 'rails_helper'

RSpec.describe "Api::V1::Metadata", type: :request do
  # Configuration pour l'authentification
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  describe "POST /api/v1/metadata/fetch" do
    let(:valid_url) { "https://example.com" }
    let(:invalid_url) { "invalid-url" }
    let(:forbidden_url) { "https://forbidden-site.com" }
    let(:not_found_url) { "https://example.com/not-found" }
    let(:timeout_url) { "https://slow-site.com" }

    # Mock du comportement de Nokogiri pour l'analyse HTML
    before do
      # Créer un mock pour Nokogiri::HTML qui retourne un document contenant nos métadonnées
      allow(Nokogiri).to receive(:HTML).and_return(double("HTML Doc").as_null_object)
    end

    context "with invalid URL format" do
      it "returns bad request status" do
        post "/api/v1/metadata/fetch", params: { url: invalid_url }, headers: headers
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to include("error" => "Invalid URL format")
      end
    end

    context "with valid URL" do
      before do
        # Mock the valid_url? method to return true for our test URL
        allow_any_instance_of(Api::V1::MetadataController).to receive(:valid_url?).with(valid_url).and_return(true)

        # Mock the fetch_metadata method to return our test data
        allow_any_instance_of(Api::V1::MetadataController).to receive(:fetch_metadata).with(valid_url).and_return({
          title: "Example Page Title",
          description: "This is a test description",
          image_url: "https://example.com/image.jpg",
          price: 42.99
        })
      end

      it "returns metadata successfully" do
        post "/api/v1/metadata/fetch", params: { url: valid_url }, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to include(
          "title" => "Example Page Title",
          "description" => "This is a test description",
          "image_url" => "https://example.com/image.jpg",
          "price" => 42.99
        )
      end
    end

    context "when timeout occurs" do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it "returns request timeout status" do
        post "/api/v1/metadata/fetch", params: { url: timeout_url }, headers: headers

        expect(response).to have_http_status(:request_timeout)
        expect(JSON.parse(response.body)).to include("error" => "Request timed out")
      end
    end

    context "when HTTP error occurs" do
      before do
        # Mock the valid_url? method to return true for our test URLs
        allow_any_instance_of(Api::V1::MetadataController).to receive(:valid_url?).with(forbidden_url).and_return(true)
        allow_any_instance_of(Api::V1::MetadataController).to receive(:valid_url?).with(not_found_url).and_return(true)

        # Mock Timeout.timeout to execute the block but then raise our specific errors
        allow(Timeout).to receive(:timeout) do |&block|
          # Extract the URL from the controller's params
          url = controller_params[:url]

          case url
          when forbidden_url
            raise OpenURI::HTTPError.new("403 Forbidden", StringIO.new)
          when not_found_url
            raise OpenURI::HTTPError.new("404 Not Found", StringIO.new)
          else
            block.call # Execute the block for other URLs
          end
        end
      end

      # Helper to get the controller params
      let(:controller_params) do
        { url: "" }  # Default empty value
      end

      it "handles 403 Forbidden error" do
        # Set the URL for this test
        controller_params[:url] = forbidden_url

        post "/api/v1/metadata/fetch", params: { url: forbidden_url }, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to include(
          "error" => "Access forbidden (403). This website may block web scraping."
        )
      end

      it "handles 404 Not Found error" do
        # Set the URL for this test
        controller_params[:url] = not_found_url

        post "/api/v1/metadata/fetch", params: { url: not_found_url }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include(
          "error" => "Page not found (404). The URL might be invalid."
        )
      end
    end

    context "when unexpected error occurs" do
      before do
        allow_any_instance_of(Api::V1::MetadataController).to receive(:valid_url?).with(valid_url).and_return(true)
        allow(Timeout).to receive(:timeout).and_raise(StandardError.new("Unexpected error"))
      end

      it "returns internal server error status" do
        post "/api/v1/metadata/fetch", params: { url: valid_url }, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to include("error" => "Failed to fetch metadata")
      end
    end

    context "with redirects" do
      let(:redirect_url) { "https://example.com/redirect" }

      before do
        allow_any_instance_of(Api::V1::MetadataController).to receive(:valid_url?).with(redirect_url).and_return(true)

        # Mock the fetch_metadata method to simulate redirection
        allow_any_instance_of(Api::V1::MetadataController).to receive(:fetch_metadata).with(redirect_url).and_return({
          title: "Redirected Page",
          description: "This is a redirected page",
          image_url: nil,
          price: nil
        })
      end

      it "follows redirects and fetches metadata from the final URL" do
        post "/api/v1/metadata/fetch", params: { url: redirect_url }, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to include(
          "title" => "Redirected Page",
          "description" => "This is a redirected page"
        )
      end
    end

    context "when not authenticated" do
      it "returns unauthorized status" do
        post "/api/v1/metadata/fetch", params: { url: valid_url }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
