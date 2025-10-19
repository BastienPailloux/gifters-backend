require 'rails_helper'

RSpec.describe "api/v1/users/show.json.jbuilder", type: :view do
  let(:user) do
    create(:user,
      name: 'John Doe',
      email: 'john@example.com',
      birthday: Date.new(1985, 3, 20),
      city: 'London',
      country: 'UK'
    )
  end

  before do
    assign(:user, user)
    render
  end

  it 'renders user wrapped in user key' do
    result = JSON.parse(rendered)
    expect(result).to have_key('user')
    expect(result['user']).to be_a(Hash)
  end

  it 'renders user using the partial' do
    result = JSON.parse(rendered)
    user_data = result['user']

    expect(user_data['id']).to eq(user.id)
    expect(user_data['name']).to eq('John Doe')
    expect(user_data['email']).to eq('john@example.com')
  end

  it 'includes all user attributes from partial' do
    result = JSON.parse(rendered)
    user_data = result['user']

    expect(user_data).to include('id', 'name', 'email', 'birthday', 'city', 'country', 'account_type')
  end
end
