json.id group.id
json.name group.name
json.description group.description
json.members_count group.respond_to?(:members_count) ? group.members_count : 0
