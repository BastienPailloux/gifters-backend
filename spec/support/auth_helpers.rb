module AuthHelpers
  def generate_jwt_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
