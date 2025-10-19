require 'rails_helper'

RSpec.describe "api/v1/users/shared_users.json.jbuilder", type: :view do
  context 'with user ids' do
    before do
      assign(:user_ids, [10, 20, 30])
      render
    end

    it 'renders user_ids array' do
      result = JSON.parse(rendered)
      expect(result).to have_key('user_ids')
      expect(result['user_ids']).to be_an(Array)
    end

    it 'renders correct user ids' do
      result = JSON.parse(rendered)
      expect(result['user_ids']).to eq([10, 20, 30])
    end
  end

  context 'with no user ids' do
    before do
      assign(:user_ids, [])
      render
    end

    it 'renders empty array' do
      result = JSON.parse(rendered)
      expect(result['user_ids']).to be_empty
    end
  end
end
