require 'rails_helper'

RSpec.describe "api/v1/users/index.json.jbuilder", type: :view do
  let!(:user1) { create(:user, name: 'Alice', email: 'alice@example.com') }
  let!(:user2) { create(:user, name: 'Bob', email: 'bob@example.com') }
  let!(:user3) { create(:user, name: 'Charlie', email: 'charlie@example.com') }

  before do
    assign(:users, [user1, user2, user3])
    render
  end

  it 'renders a users array' do
    result = JSON.parse(rendered)
    expect(result).to have_key('users')
    expect(result['users']).to be_an(Array)
  end

  it 'renders all users' do
    result = JSON.parse(rendered)
    expect(result['users'].size).to eq(3)
  end

  it 'renders only id, name, and email for each user' do
    result = JSON.parse(rendered)
    user = result['users'].first

    expect(user.keys).to contain_exactly('id', 'name', 'email')
  end

  it 'renders correct user data' do
    result = JSON.parse(rendered)
    user_names = result['users'].map { |u| u['name'] }
    user_emails = result['users'].map { |u| u['email'] }

    expect(user_names).to include('Alice', 'Bob', 'Charlie')
    expect(user_emails).to include('alice@example.com', 'bob@example.com', 'charlie@example.com')
  end
end
