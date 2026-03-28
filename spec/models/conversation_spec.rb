require 'rails_helper'

RSpec.describe Conversation, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:last_activity_at) }
  end

  describe '.title_from' do
    it 'truncates to 60 chars at a word boundary' do
      long = 'mot ' * 20
      expect(Conversation.title_from(long).length).to be <= 60
    end

    it 'returns the text as-is if under 60 chars' do
      expect(Conversation.title_from('Bonjour')).to eq('Bonjour')
    end
  end

  describe '.recent scope' do
    it 'orders by last_activity_at descending' do
      old = create(:conversation, user: user, last_activity_at: 1.hour.ago)
      recent = create(:conversation, user: user, last_activity_at: 1.minute.ago)
      expect(Conversation.recent.first).to eq(recent)
      expect(Conversation.recent.last).to eq(old)
    end
  end
end
