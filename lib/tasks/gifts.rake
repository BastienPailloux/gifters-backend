# frozen_string_literal: true

namespace :gifts do
  desc 'Backfill Mistral embeddings for all gift ideas without embedding'
  task backfill_embeddings: :environment do
    service = MistralEmbeddingService.new
    scope = GiftIdea.where(embedding: nil)
    total = scope.count

    puts "Backfilling embeddings for #{total} gift ideas..."

    scope.find_each.with_index(1) do |gift_idea, i|
      text = "#{gift_idea.title} #{gift_idea.description}".strip
      embedding = service.embed(text)
      gift_idea.update_column(:embedding, embedding)
      puts "#{i}/#{total}: [#{gift_idea.id}] #{gift_idea.title}"
    rescue StandardError => e
      puts "ERROR [#{gift_idea.id}] #{gift_idea.title}: #{e.message}"
    end

    puts "Done."
  end
end
