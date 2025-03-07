class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :created_gift_ideas, class_name: 'GiftIdea', foreign_key: 'created_by_id', dependent: :destroy
  has_many :received_gift_ideas, class_name: 'GiftIdea', foreign_key: 'for_user_id', dependent: :destroy
end
