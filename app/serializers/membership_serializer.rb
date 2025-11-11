class MembershipSerializer < ActiveModel::Serializer
  attributes :id, :membership_id, :name, :email, :role, :account_type, :parent_id

  # L'ID principal est l'user_id pour la compatibilité avec le frontend
  def id
    object.user.id
  end

  # L'ID du membership pour les actions REST (update, delete)
  def membership_id
    object.id
  end

  # Les attributs de l'utilisateur
  def name
    object.user.name
  end

  def email
    object.user.email
  end

  def account_type
    object.user.account_type
  end

  def parent_id
    object.user.parent_id
  end

  # Le rôle vient du membership lui-même
  def role
    object.role
  end
end
