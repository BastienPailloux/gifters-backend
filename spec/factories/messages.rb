FactoryBot.define do
  factory :message do
    association :conversation
    role { 'user' }
    sequence(:content) { |n| "Message #{n}" }
  end
end
