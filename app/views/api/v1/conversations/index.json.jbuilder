json.array! @conversations do |conversation|
  json.partial! 'api/v1/conversations/conversation', conversation: conversation
end
