class GiftIdea < ApplicationRecord
  belongs_to :for_user, class_name: 'User'
  belongs_to :created_by, class_name: 'User'
end
