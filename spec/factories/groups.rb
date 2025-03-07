FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    description { "A test group description" }
    sequence(:invite_code) { |n| "INVITE#{n}" }
  end
end
