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
  validates :link, format: { with: URI::regexp, message: "n'est pas une URL valide" }, allow_blank: true
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
  scope :created_by_children, ->(user) { where(created_by_id: User.where(parent_id: user.id).select(:id)) }
  scope :not_for_user, ->(user) {
    where.not(id: GiftRecipient.where(user_id: user.id).select(:gift_idea_id))
  }
  scope :for_children, ->(user) { where(id: GiftRecipient.where(user_id: User.where(parent_id: user.id).select(:id)).select(:gift_idea_id)) }
  scope :for_users_in_common_groups, ->(user) {
    # Cette requête trouve les idées de cadeaux où tous les destinataires ont un groupe commun avec l'utilisateur
    gift_idea_ids_with_recipient_count = GiftRecipient.group(:gift_idea_id).count

    # Pour chaque idée de cadeau, compter combien de destinataires ont un groupe commun avec l'utilisateur
    gift_idea_ids_with_common_group_count =
      GiftRecipient.joins("INNER JOIN memberships AS recipient_memberships ON gift_recipients.user_id = recipient_memberships.user_id")
                  .joins("INNER JOIN memberships AS user_memberships ON recipient_memberships.group_id = user_memberships.group_id")
                  .where("user_memberships.user_id = ?", user.id)
                  .select("gift_recipients.gift_idea_id, COUNT(DISTINCT gift_recipients.user_id) as recipient_count_with_common_group")
                  .group("gift_recipients.gift_idea_id")
                  .to_a
                  .map { |r| [r.gift_idea_id, r.recipient_count_with_common_group.to_i] }
                  .to_h

    # Trouver les idées de cadeaux où le nombre de destinataires avec un groupe commun
    # est égal au nombre total de destinataires
    gift_idea_ids = gift_idea_ids_with_recipient_count.keys.select do |gift_idea_id|
      total_recipients = gift_idea_ids_with_recipient_count[gift_idea_id]
      recipients_with_common_group = gift_idea_ids_with_common_group_count[gift_idea_id] || 0
      recipients_with_common_group == total_recipients
    end

    where(id: gift_idea_ids)
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

    # Cette requête trouve les idées de cadeaux où tous les destinataires sont dans le groupe
    gift_idea_ids_with_recipient_count = GiftRecipient.group(:gift_idea_id).count

    # Pour chaque idée de cadeau, compter combien de destinataires sont membres du groupe
    gift_idea_ids_with_group_membership_count =
      GiftRecipient.joins("INNER JOIN memberships ON gift_recipients.user_id = memberships.user_id")
                  .where("memberships.group_id = ?", group_id)
                  .select("gift_recipients.gift_idea_id, COUNT(DISTINCT gift_recipients.user_id) as recipient_count_in_group")
                  .group("gift_recipients.gift_idea_id")
                  .to_a
                  .map { |r| [r.gift_idea_id, r.recipient_count_in_group.to_i] }
                  .to_h

    # Trouver les idées de cadeaux où le nombre de destinataires membres du groupe
    # est égal au nombre total de destinataires
    gift_idea_ids = gift_idea_ids_with_recipient_count.keys.select do |gift_idea_id|
      total_recipients = gift_idea_ids_with_recipient_count[gift_idea_id]
      recipients_in_group = gift_idea_ids_with_group_membership_count[gift_idea_id] || 0
      recipients_in_group == total_recipients
    end

    where(id: gift_idea_ids)
  }

  # Scope principal pour les idées visibles par un utilisateur
  scope :visible_to_user, ->(user) {
    created_by_user(user)
      .or(
        not_for_user(user)
          .for_users_in_common_groups(user)
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
    # Si le cadeau est acheté...
    if status == 'bought'
      # Le créateur et l'acheteur peuvent toujours voir le cadeau acheté
      return true if created_by_id == user.id || buyer_id == user.id
      # Pour les autres, ils ne peuvent pas voir le cadeau acheté
      return false
    end

    # Le créateur peut toujours voir ses propres cadeaux
    return true if created_by_id == user.id

    # Le destinataire ne peut pas voir le cadeau qui lui est destiné
    # (sauf s'il est aussi le créateur, ce qui est déjà vérifié ci-dessus)
    return false if is_recipient?(user)

    # Pour les autres utilisateurs, ils doivent avoir un groupe en commun avec tous les destinataires
    recipients.all? { |r| user.has_common_group_with?(r) }
  end

  # Vérifier si un utilisateur est destinataire de ce cadeau
  def is_recipient?(user)
    gift_recipients.exists?(user_id: user.id)
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
    # Utiliser la logique de la policy pour vérifier les autorisations
    recipients.each do |recipient|
      unless GiftIdeaPolicy.can_create_for_recipient?(created_by, recipient)
        errors.add(:recipients, "must all be in a common group with you or be a family member")
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
