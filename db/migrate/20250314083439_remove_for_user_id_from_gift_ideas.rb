class RemoveForUserIdFromGiftIdeas < ActiveRecord::Migration[7.1]
  def change
    # Supprimer la clé étrangère avant de supprimer la colonne
    remove_foreign_key :gift_ideas, column: :for_user_id
    remove_column :gift_ideas, :for_user_id
  end
end
