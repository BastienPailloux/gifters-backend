FactoryBot.define do
  factory :gift_idea do
    sequence(:title) { |n| "Gift Idea #{n}" }
    description { "A test gift idea description" }
    price { 19.99 }
    link { "https://example.com/gift" }
    image_url { "https://example.com/gift.jpg" }
    association :for_user, factory: :user
    association :created_by, factory: :user
    status { "proposed" }

    trait :buying do
      status { "buying" }
    end

    trait :bought do
      status { "bought" }
    end
  end
end
