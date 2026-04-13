# frozen_string_literal: true

class BackfillUserEmbeddings < ActiveRecord::Migration[8.0]
  def up
    User.where(embedding: nil).find_each do |user|
      user.background_generate_embedding
    end
  end

  def down
    # irreversible — embeddings are regeneratable at any time
  end
end
