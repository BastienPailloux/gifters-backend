class Message < ApplicationRecord
  belongs_to :conversation

  validates :content, presence: true
  validates :role, inclusion: { in: %w[user assistant] }
end
