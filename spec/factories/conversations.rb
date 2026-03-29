FactoryBot.define do
  factory :conversation do
    association :user
    sequence(:title) { |n| "Conversation #{n}" }
    last_activity_at { Time.current }
  end
end
