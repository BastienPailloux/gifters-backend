# frozen_string_literal: true

module ChildAuthorization
  # Vérifie si l'utilisateur OU un de ses enfants remplit une condition
  # en utilisant une requête SQL optimisée
  #
  # @param model [Class] Le modèle ActiveRecord à vérifier (ex: Membership, User)
  # @param conditions [Hash] Les conditions SQL à vérifier
  # @return [Boolean]
  #
  # Exemple d'usage :
  #   authorized_for_user_or_children?(Membership, user_id: user.id, group_id: record.group_id, role: 'admin')
  #   # Vérifie si user OU un de ses enfants est admin du groupe
  def authorized_for_user_or_children?(model, conditions)
    # Construire les conditions pour l'utilisateur
    user_conditions = conditions.dup

    # Vérifier si l'utilisateur remplit la condition
    return true if model.exists?(user_conditions)

    # Si l'utilisateur a un user_id dans les conditions, le remplacer par les IDs des enfants
    if user_conditions.key?(:user_id)
      children_conditions = user_conditions.dup
      children_conditions[:user_id] = User.where(parent_id: user.id).select(:id)

      # Vérifier si un enfant remplit la condition (1 seule requête)
      return model.exists?(children_conditions)
    end

    false
  end

  # Vérifie si l'utilisateur OU un de ses enfants fait partie d'un groupe
  def member_or_child_member_of?(group)
    return true if group.users.include?(user)

    # Vérifier si un enfant est membre (1 seule requête)
    Membership.exists?(
      user_id: User.where(parent_id: user.id).select(:id),
      group_id: group.id
    )
  end

  # Vérifie si l'utilisateur OU un de ses enfants est admin d'un groupe
  def admin_or_child_admin_of?(group)
    return true if group.admin_users.include?(user)

    # Vérifier si un enfant est admin (1 seule requête)
    Membership.exists?(
      user_id: User.where(parent_id: user.id).select(:id),
      group_id: group.id,
      role: 'admin'
    )
  end

  # Vérifie si un record appartient à l'utilisateur OU à un de ses enfants
  # Le record doit avoir un attribut created_by_id ou user_id
  def owned_by_user_or_children?(record, owner_field: :created_by_id)
    owner_id = record.send(owner_field)
    return false unless owner_id

    return true if owner_id == user.id

    # Vérifier si c'est un enfant (1 seule requête)
    User.exists?(id: owner_id, parent_id: user.id)
  end
end
