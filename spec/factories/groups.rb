FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    sequence(:description) { |n| "Description for Group #{n}" }
  end
end
