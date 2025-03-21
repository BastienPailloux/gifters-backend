class AddNewsletterSubscriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :newsletter_subscription, :boolean, default: false, null: false
    add_index :users, :newsletter_subscription
  end
end
