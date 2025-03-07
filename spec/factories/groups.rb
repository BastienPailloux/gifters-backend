FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    description { "A test group description" }
  end
end
