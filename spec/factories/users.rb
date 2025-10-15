FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    account_type { "standard" }

    # Factory pour un compte enfant (managed)
    factory :managed_user do
      email { nil }
      password { nil }
      account_type { "managed" }
      association :parent, factory: :user
    end
  end
end
