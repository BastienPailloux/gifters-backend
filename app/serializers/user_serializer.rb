class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email

  # Ne pas inclure l'email si ce n'est pas l'utilisateur courant ou un admin
  def attributes(*args)
    hash = super
    unless current_user == object || current_user&.admin?
      hash = hash.except(:email)
    end
    hash
  end

  private

  def current_user
    scope
  end
end
