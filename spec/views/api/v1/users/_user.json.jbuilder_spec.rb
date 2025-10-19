require 'rails_helper'

RSpec.describe "api/v1/users/_user.json.jbuilder", type: :view do
  let(:user) do
    create(:user,
      name: 'Test User',
      email: 'test@example.com',
      birthday: Date.new(1990, 5, 15),
      gender: 'male',
      phone_number: '+33612345678',
      address: '123 Main St',
      city: 'Paris',
      state: 'Île-de-France',
      zip_code: '75001',
      country: 'France',
      locale: 'fr',
      newsletter_subscription: true
    )
  end

  before do
    render partial: 'api/v1/users/user', locals: { user: user }
  end

  it 'renders user id' do
    result = JSON.parse(rendered)
    expect(result['id']).to eq(user.id)
  end

  it 'renders user name' do
    result = JSON.parse(rendered)
    expect(result['name']).to eq('Test User')
  end

  it 'renders user email' do
    result = JSON.parse(rendered)
    expect(result['email']).to eq('test@example.com')
  end

  it 'renders user birthday' do
    result = JSON.parse(rendered)
    expect(result['birthday']).to eq('1990-05-15')
  end

  it 'renders user profile information' do
    result = JSON.parse(rendered)
    expect(result['gender']).to eq('male')
    expect(result['phone_number']).to eq('+33612345678')
    expect(result['address']).to eq('123 Main St')
    expect(result['city']).to eq('Paris')
    expect(result['state']).to eq('Île-de-France')
    expect(result['zip_code']).to eq('75001')
    expect(result['country']).to eq('France')
  end

  it 'renders user preferences' do
    result = JSON.parse(rendered)
    expect(result['locale']).to eq('fr')
    expect(result['newsletter_subscription']).to be true
  end

  it 'renders account type' do
    result = JSON.parse(rendered)
    expect(result['account_type']).to eq('standard')
  end

  it 'renders parent_id' do
    result = JSON.parse(rendered)
    expect(result['parent_id']).to be_nil
  end

  it 'renders timestamps' do
    result = JSON.parse(rendered)
    expect(result).to have_key('created_at')
    expect(result).to have_key('updated_at')
  end

  it 'includes all expected attributes' do
    result = JSON.parse(rendered)
    expected_keys = %w[
      id name email birthday gender phone_number address city state
      zip_code country locale newsletter_subscription account_type
      parent_id created_at updated_at
    ]
    expect(result.keys).to match_array(expected_keys)
  end
end
