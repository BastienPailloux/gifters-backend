class Group < ApplicationRecord
  # Relations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy
  attr_accessor :creator

  # Validations
  validates :name, presence: true

  # Callbacks
  after_create :create_initial_invitation

  # Methods
  def add_user(user, role = 'member')
    existing_membership = memberships.find_by(user: user)
    if existing_membership
      existing_membership.update(role: role)
      existing_membership
    else
      # Garder une référence au créateur si c'est un admin
      self.creator = user if role == 'admin' && self.creator.nil?
      memberships.create(user: user, role: role)
    end
  end

  def admin_users
    memberships.where(role: 'admin').map(&:user)
  end

  def admin_count
    memberships.where(role: 'admin').count
  end

  def members_count
    memberships.count
  end

  def create_invitation(created_by, role = 'member')
    invitations.create(created_by: created_by, role: role)
  end

  private

  # Crée automatiquement une invitation initiale pour le groupe
  def create_initial_invitation
    # Tentative d'utiliser l'attribut creator s'il est défini
    creator_user = self.creator

    # Sinon, chercher le premier admin
    if creator_user.nil?
      creator_user = admin_users.first
    end

    # Si nous avons un créateur, nous pouvons créer l'invitation
    if creator_user.present?
      create_invitation(creator_user, 'member')
    else
      # On programmera la création de l'invitation pour plus tard
      Rails.logger.warn("Impossible de créer l'invitation initiale pour le groupe #{id} - Aucun admin trouvé immédiatement")
    end
  end
end
