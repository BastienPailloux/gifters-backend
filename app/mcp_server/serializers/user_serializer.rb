# frozen_string_literal: true

module Serializers
  class UserSerializer
    def self.serialize_compact(user)
      { id: user.id, name: user.name, account_type: user.account_type }
    end

    def self.serialize_full(user, current_user)
      common_groups = user.groups & current_user.groups
      visible_child_ids = current_user.common_groups_with_users_ids
      managed_children = User.where(parent_id: user.id)
                             .where(id: visible_child_ids)
                             .map { |c| serialize_compact(c) }
      {
        id:               user.id,
        name:             user.name,
        account_type:     user.account_type,
        common_groups:    common_groups.map { |g| { id: g.id, name: g.name } },
        managed_children: managed_children
      }
    end
  end
end
