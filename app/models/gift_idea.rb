class GiftIdea < ApplicationRecord
  belongs_to :for_user, class_name: 'User'
  belongs_to :created_by, class_name: 'User'
  belongs_to :buyer, class_name: 'User', optional: true

  # Constants
  STATUSES = %w[proposed buying bought].freeze

  # Validations
  validates :title, presence: true
  validates :link, presence: true, format: { with: URI::regexp, message: "n'est pas une URL valide" }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :creator_and_receiver_have_common_group

  # Callbacks
  before_validation :set_default_status

  # Scopes
  scope :proposed, -> { where(status: 'proposed') }
  scope :buying, -> { where(status: 'buying') }
  scope :bought, -> { where(status: 'bought') }
  scope :for_recipient, ->(user_id) { where(for_user_id: user_id) }
  scope :created_by_user, ->(user) { where(created_by: user) }
  scope :not_for_user, ->(user) { where.not(for_user: user) }
  scope :for_users_in_common_groups, ->(user) {
    where(for_user_id: user.common_groups_with_users_ids)
  }
  scope :bought_by_user, ->(user) { where(buyer: user) }

  # Scope principal pour les idées visibles par un utilisateur
  scope :visible_to_user, ->(user) {
    created_by_user(user)
      .or(
        not_for_user(user)
          .where(for_user_id: user.common_groups_with_users_ids)
      )
  }

  # Methods
  def mark_as_buying(user = nil)
    update(status: 'buying', buyer: user) if user
  end

  def mark_as_bought(user = nil)
    buyer_to_set = user || self.buyer
    update(status: 'bought', buyer: buyer_to_set)
  end

  def visible_to?(user)
    return false if status == 'bought'
    return false if for_user_id == user.id
    return true if created_by_id == user.id
    for_user.has_common_group_with?(user)
  end

  private

  def creator_and_receiver_have_common_group
    return if created_by.has_common_group_with?(for_user) || created_by_id == for_user_id
    errors.add(:for_user, "must be in a common group with you")
  end

  def set_default_status
    self.status ||= 'proposed'
  end
end
