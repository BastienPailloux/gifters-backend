class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email

  # Ne pas inclure l'email si ce n'est pas l'utilisateur courant
  def attributes(*args)
    hash = super
    unless current_user == object
      hash = hash.except(:email)
    end
    hash
  end

  private

  def current_user
    scope
  end
end
