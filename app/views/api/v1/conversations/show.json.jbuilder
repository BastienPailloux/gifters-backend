json.partial! 'api/v1/conversations/conversation', conversation: @conversation
json.messages @conversation.messages.order(:created_at) do |message|
  json.id message.id
  json.role message.role
  json.content message.content
  json.created_at message.created_at
end
