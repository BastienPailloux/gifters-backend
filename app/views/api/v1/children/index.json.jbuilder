json.children @children do |child|
  json.partial! 'api/v1/users/user', user: child
end
