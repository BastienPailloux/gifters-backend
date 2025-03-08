FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-03-08 09:39:49" }
  end
end
