require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns a welcome message" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("message" => "Welcome to Gifters API")
    end
  end
end
