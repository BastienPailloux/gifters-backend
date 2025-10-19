# Informations de base du groupe
json.partial! 'api/v1/groups/group', group: @group

# Membres du groupe avec leurs rôles
json.members @memberships do |membership|
  json.id membership.user.id
  json.name membership.user.name
  json.email membership.user.email
  json.role membership.role
end
