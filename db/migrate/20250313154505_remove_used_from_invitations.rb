class RemoveUsedFromInvitations < ActiveRecord::Migration[7.1]
  def change
    remove_column :invitations, :used, :boolean
  end
end
