json.child do
  json.partial! 'api/v1/users/user', user: @child
end
