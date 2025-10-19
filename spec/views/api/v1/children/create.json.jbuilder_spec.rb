require 'rails_helper'

RSpec.describe "api/v1/children/create.json.jbuilder", type: :view do
  let(:child) do
    create(:managed_user,
      name: 'New Child',
      birthday: Date.new(2019, 1, 10)
    )
  end

  before do
    assign(:child, child)
    render
  end

  it 'renders created child wrapped in child key' do
    result = JSON.parse(rendered)
    expect(result).to have_key('child')
    expect(result['child']).to be_a(Hash)
  end

  it 'renders child using the user partial' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data['id']).to eq(child.id)
    expect(child_data['name']).to eq('New Child')
    expect(child_data['account_type']).to eq('managed')
  end

  it 'includes success message' do
    result = JSON.parse(rendered)
    expect(result).to have_key('message')
    expect(result['message']).to eq('Child account created successfully')
  end

  it 'renders all child attributes' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data).to include(
      'id', 'name', 'birthday', 'account_type', 'parent_id'
    )
  end
end
