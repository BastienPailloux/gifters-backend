# Informations de base du groupe
json.partial! 'api/v1/groups/group', group: @group

json.members @memberships do |membership|
  json.id membership.user.id
  json.membershipId membership.id
  json.name membership.user.name
  json.email membership.user.email
  json.role membership.role
  json.accountType membership.user.account_type
  json.parentId membership.user.parent_id
end
