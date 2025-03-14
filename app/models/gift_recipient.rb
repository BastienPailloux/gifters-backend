class GiftRecipient < ApplicationRecord
  belongs_to :gift_idea
  belongs_to :user

  validates :gift_idea_id, uniqueness: { scope: :user_id }
end
