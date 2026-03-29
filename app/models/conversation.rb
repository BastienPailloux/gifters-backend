class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :title, presence: true
  validates :last_activity_at, presence: true

  scope :recent, -> { order(last_activity_at: :desc) }

  def self.title_from(text)
    truncated = text.to_s.truncate(60, separator: ' ', omission: '')
    truncated.strip.presence || text.to_s[0..59]
  end
end
