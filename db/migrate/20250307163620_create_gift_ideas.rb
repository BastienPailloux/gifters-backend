class CreateGiftIdeas < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_ideas do |t|
      t.string :title
      t.text :description
      t.decimal :price
      t.string :link
      t.string :image_url
      t.references :for_user, null: false, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :status

      t.timestamps
    end
  end
end
