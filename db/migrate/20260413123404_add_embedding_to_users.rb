# frozen_string_literal: true

class AddEmbeddingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :embedding, :vector, limit: 1024
  end
end
