FactoryBot.define do
  factory :invitation do
    group
    association :created_by, factory: :user
    role { 'member' }

    trait :admin do
      role { 'admin' }
    end
  end
end
