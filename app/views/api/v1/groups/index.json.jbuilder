# Si le paramètre with_children est présent, on retourne la structure hiérarchique
if @children
  json.id @user.id
  json.name @user.name
  json.account_type @user.account_type

  json.groups @groups do |group|
    json.partial! 'api/v1/groups/group', group: group
  end

  json.children @children do |child|
    json.id child.id
    json.name child.name

    json.groups child.groups do |group|
      json.partial! 'api/v1/groups/group', group: group
    end
  end
else
  # Sinon, on retourne juste la liste des groupes (format simple)
  json.array! @groups do |group|
    json.partial! 'api/v1/groups/group', group: group
  end
end
