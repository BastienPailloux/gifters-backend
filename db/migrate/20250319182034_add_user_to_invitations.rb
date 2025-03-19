class AddUserToInvitations < ActiveRecord::Migration[7.1]
  def change
    add_reference :invitations, :user, null: true, foreign_key: true
  end
end
