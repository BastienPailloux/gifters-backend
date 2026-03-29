# frozen_string_literal: true

class EnablePgvectorAndAddEmbeddingToGiftIdeas < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"
    add_column :gift_ideas, :embedding, :vector, limit: 1024
  end
end
