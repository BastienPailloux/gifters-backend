class AddIndexToConversationsUserIdLastActivityAt < ActiveRecord::Migration[8.0]
  def change
    add_index :conversations, [:user_id, :last_activity_at]
  end
end
