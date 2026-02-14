json.id group.id
json.name group.name
json.description group.description
json.members_count group.respond_to?(:members_count) ? group.members_count : 0

# Permissions de l'utilisateur actuel
json.permissions do
  json.can_administer policy(group).update?
  json.is_direct_admin group.admin_users.include?(@current_user)
  json.is_member group.users.include?(@current_user)
end

# Informations sur qui est membre de ce groupe
json.membershipInfo do
  is_user_member = group.users.include?(@current_user)
  children_members = @current_user.children.select { |child| group.users.include?(child) }
  
  json.isUserMember is_user_member
  json.childrenMembers children_members do |child|
    json.id child.id
    json.name child.name
  end
end
