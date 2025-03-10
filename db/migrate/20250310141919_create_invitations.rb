class CreateInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :invitations do |t|
      t.string :token, null: false
      t.references :group, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false, default: 'member'
      t.boolean :used, null: false, default: false

      t.timestamps
    end
    add_index :invitations, :token, unique: true
  end
end
