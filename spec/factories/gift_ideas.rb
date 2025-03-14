FactoryBot.define do
  factory :gift_idea do
    sequence(:title) { |n| "Gift Idea #{n}" }
    description { "A test gift idea description" }
    price { 19.99 }
    link { "https://example.com/gift" }
    image_url { "https://example.com/gift.jpg" }
    association :created_by, factory: :user
    status { "proposed" }

    # Désactiver temporairement les validations pendant les tests
    to_create do |instance|
      instance.save(validate: false)
    end

    # Ajouter un recipient à la fois pour build et create
    after(:build) do |gift_idea|
      # Si aucun destinataire n'a été ajouté manuellement, en ajouter un par défaut
      if gift_idea.recipients.empty?
        recipient = create(:user)
        group = create(:group)
        # Ajouter le créateur et le destinataire au même groupe
        create(:membership, user: gift_idea.created_by, group: group)
        create(:membership, user: recipient, group: group)
        # Ajouter le destinataire à l'idée de cadeau
        gift_idea.recipients << recipient
      end
    end

    # Trait pour ajouter automatiquement un destinataire spécifique
    trait :with_recipient do
      transient do
        recipient { create(:user) }
      end

      after(:build) do |gift_idea, evaluator|
        gift_idea.recipients << evaluator.recipient
      end
    end

    trait :buying do
      status { "buying" }
    end

    trait :bought do
      status { "bought" }
    end
  end
end
