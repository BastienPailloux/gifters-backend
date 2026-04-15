# frozen_string_literal: true

module Serializers
  class InvitationSerializer
    def self.serialize(invitation)
      {
        id:              invitation.id,
        role:            invitation.role,
        invitation_url:  invitation.invitation_url,
        created_by_id:   invitation.created_by_id,
        created_by_name: invitation.created_by&.name
      }
    end
  end
end
