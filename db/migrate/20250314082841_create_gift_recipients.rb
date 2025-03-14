class CreateGiftRecipients < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_recipients do |t|
      t.references :gift_idea, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :gift_recipients, [:gift_idea_id, :user_id], unique: true
  end
end
