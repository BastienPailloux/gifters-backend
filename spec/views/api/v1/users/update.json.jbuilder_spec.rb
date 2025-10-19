require 'rails_helper'

RSpec.describe "api/v1/users/update.json.jbuilder", type: :view do
  let(:user) do
    create(:user,
      name: 'Jane Updated',
      email: 'jane.updated@example.com',
      city: 'Paris',
      newsletter_subscription: true
    )
  end

  before do
    assign(:user, user)
    render
  end

  it 'renders updated user wrapped in user key' do
    result = JSON.parse(rendered)
    expect(result).to have_key('user')
    expect(result['user']).to be_a(Hash)
  end

  it 'renders updated user data using the partial' do
    result = JSON.parse(rendered)
    user_data = result['user']

    expect(user_data['name']).to eq('Jane Updated')
    expect(user_data['email']).to eq('jane.updated@example.com')
    expect(user_data['city']).to eq('Paris')
    expect(user_data['newsletter_subscription']).to be true
  end

  it 'includes all user attributes' do
    result = JSON.parse(rendered)
    user_data = result['user']

    expect(user_data).to include(
      'id', 'name', 'email', 'city', 'newsletter_subscription', 'account_type'
    )
  end
end
