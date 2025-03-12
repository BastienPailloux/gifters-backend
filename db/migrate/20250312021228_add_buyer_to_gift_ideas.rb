class AddBuyerToGiftIdeas < ActiveRecord::Migration[7.1]
  def change
    add_column :gift_ideas, :buyer_id, :integer
    add_index :gift_ideas, :buyer_id
    add_foreign_key :gift_ideas, :users, column: :buyer_id
  end
end
