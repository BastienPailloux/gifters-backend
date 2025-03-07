class AddInviteCodeToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :invite_code, :string
    add_index :groups, :invite_code, unique: true
  end
end
