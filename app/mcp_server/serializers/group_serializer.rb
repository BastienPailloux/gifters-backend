# frozen_string_literal: true

module Serializers
  class GroupSerializer
    def self.serialize_compact(group)
      {
        id:            group.id,
        name:          group.name,
        members_count: group.members_count
      }
    end

    def self.serialize_full(group, current_user)
      loaded_memberships = group.memberships.includes(:user).to_a
      membership = loaded_memberships.find { |m| m.user_id == current_user.id }
      members = loaded_memberships.map do |m|
        {
          id:           m.user.id,
          name:         m.user.name,
          account_type: m.user.account_type,
          role:         m.role
        }
      end
      invitations = group.invitations.map { |i| Serializers::InvitationSerializer.serialize(i) }
      serialize_compact(group).merge(
        members_count:     loaded_memberships.size,
        current_user_role: membership&.role,
        members:           members,
        invitations:       invitations
      )
    end
  end
end
