class RemoveInviteCodeFromGroups < ActiveRecord::Migration[7.1]
  def change
    remove_column :groups, :invite_code, :string
  end
end
