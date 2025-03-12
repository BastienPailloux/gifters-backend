class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email

  # Ne pas inclure l'email si ce n'est pas l'utilisateur courant ou un admin
  def attributes(*args)
    hash = super
    unless scope == object || scope.admin?
      hash = hash.except(:email)
    end
    hash
  end
end
