class HomeController < ApplicationController
  def index
    render json: { message: "Welcome to Gifters API" }
  end
end
