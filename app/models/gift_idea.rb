class GiftIdea < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  belongs_to :buyer, class_name: 'User', optional: true

  # Relation many-to-many avec les destinataires
  has_many :gift_recipients, dependent: :destroy
  has_many :recipients, through: :gift_recipients, source: :user

  # Constants
  STATUSES = %w[proposed buying bought].freeze

  # Validations
  validates :title, presence: true
  validates :link, presence: true, format: { with: URI::regexp, message: "n'est pas une URL valide" }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :creator_and_recipients_have_common_group
  validate :at_least_one_recipient

  # Callbacks
  before_validation :set_default_status

  # Scopes
  scope :proposed, -> { where(status: 'proposed') }
  scope :buying, -> { where(status: 'buying') }
  scope :bought, -> { where(status: 'bought') }
  scope :for_recipient, ->(user_id) {
    joins(:recipients).where(gift_recipients: { user_id: user_id })
  }
  scope :created_by_user, ->(user) { where(created_by: user) }
  scope :not_for_user, ->(user) {
    where.not(id: GiftRecipient.where(user_id: user.id).select(:gift_idea_id))
  }
  scope :for_users_in_common_groups, ->(user) {
    # Trouver les idées où au moins un destinataire est dans un groupe commun avec l'utilisateur
    where(id: GiftRecipient.joins("INNER JOIN memberships AS recipient_memberships ON gift_recipients.user_id = recipient_memberships.user_id")
                           .joins("INNER JOIN memberships AS user_memberships ON recipient_memberships.group_id = user_memberships.group_id")
                           .where("user_memberships.user_id = ?", user.id)
                           .select(:gift_idea_id))
  }
  scope :bought_by_user, ->(user) { where(buyer: user) }

  # Scope pour filtrer par acheteur
  scope :with_buyer, ->(buyer_id) {
    # Si l'acheteur existe, retourner les cadeaux correspondants
    buyer_id.present? && User.exists?(buyer_id) ? where(buyer_id: buyer_id) : none
  }

  # Scope pour filtrer par groupe
  scope :for_group, ->(group_id) {
    group = Group.find_by(id: group_id)
    return none unless group

    # Inclure les idées pour les destinataires dans ce groupe
    where(id: GiftRecipient.joins("INNER JOIN memberships ON gift_recipients.user_id = memberships.user_id")
                          .where("memberships.group_id = ?", group_id)
                          .select(:gift_idea_id))
  }

  # Scope principal pour les idées visibles par un utilisateur
  scope :visible_to_user, ->(user) {
    created_by_user(user)
      .or(
        not_for_user(user)
          .where(id: GiftRecipient.joins("INNER JOIN memberships AS recipient_memberships ON gift_recipients.user_id = recipient_memberships.user_id")
                                 .joins("INNER JOIN memberships AS user_memberships ON recipient_memberships.group_id = user_memberships.group_id")
                                 .where("user_memberships.user_id = ?", user.id)
                                 .select(:gift_idea_id))
      )
  }

  # Methods
  def mark_as_buying(user = nil)
    # Mettre à jour le statut même si aucun utilisateur n'est fourni
    result = update(status: 'buying')
    # Si un utilisateur est fourni, mettre à jour l'acheteur également
    update(buyer: user) if user && result
    result
  end

  def mark_as_bought(user = nil)
    buyer_to_set = user || self.buyer
    update(status: 'bought', buyer: buyer_to_set)
  end

  def visible_to?(user)
    return false if status == 'bought'
    return true if created_by_id == user.id

    # Vérifier si l'utilisateur est un destinataire
    return false if is_recipient?(user)

    # Vérifier si l'utilisateur a un groupe en commun avec au moins un destinataire
    recipients.any? { |recipient| recipient.has_common_group_with?(user) }
  end

  # Vérifier si un utilisateur est destinataire de ce cadeau
  def is_recipient?(user)
    recipients.include?(user)
  end

  # Ajouter un destinataire
  def add_recipient(user)
    # Éviter les doublons
    return if recipients.include?(user)
    recipients << user
  end

  # Supprimer un destinataire
  def remove_recipient(user)
    gift_recipients.where(user_id: user.id).destroy_all
  end

  # Récupérer tous les destinataires
  def all_recipients
    recipients.to_a
  end

  private

  def creator_and_recipients_have_common_group
    # Vérifier que le créateur a un groupe en commun avec chaque destinataire
    recipients.each do |recipient|
      unless created_by.has_common_group_with?(recipient) || created_by_id == recipient.id
        errors.add(:recipients, "must all be in a common group with you")
        return false
      end
    end

    true
  end

  def at_least_one_recipient
    if recipients.empty?
      errors.add(:base, "Gift idea must have at least one recipient")
    end
  end

  def set_default_status
    self.status ||= 'proposed'
  end
end
