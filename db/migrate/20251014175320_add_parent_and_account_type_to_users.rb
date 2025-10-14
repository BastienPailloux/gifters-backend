class AddParentAndAccountTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :parent_id, :bigint
    add_column :users, :account_type, :string, default: 'standard', null: false

    add_index :users, :parent_id
    add_foreign_key :users, :users, column: :parent_id
  end
end
