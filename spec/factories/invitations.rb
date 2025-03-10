FactoryBot.define do
  factory :invitation do
    association :group
    association :created_by, factory: :user
    role { 'member' }
    used { false }

    trait :admin do
      role { 'admin' }
    end

    trait :used do
      used { true }
    end
  end
end
