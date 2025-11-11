# Contract pour valider les paramètres d'acceptation d'invitation
module Invitations
  class AcceptInvitationContract < Dry::Validation::Contract
    params do
      required(:invitation).value(:any)
      required(:current_user).value(:any)
      required(:user_ids).value(:array).each(:integer)
    end

    rule(:invitation) do
      key.failure('must be a valid Invitation') unless value.is_a?(Invitation)
    end

    rule(:current_user) do
      key.failure('must be a valid User') unless value.is_a?(User)
    end

    rule(:user_ids) do
      key.failure('cannot be empty') if value.empty?

      # Vérifier que les IDs sont positifs
      unless value.all? { |id| id > 0 }
        key.failure('all IDs must be positive')
      end
    end
  end
end
