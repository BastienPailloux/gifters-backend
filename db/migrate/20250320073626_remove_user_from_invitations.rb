class RemoveUserFromInvitations < ActiveRecord::Migration[7.1]
  def change
    remove_reference :invitations, :user, null: true, foreign_key: true
  end
end
