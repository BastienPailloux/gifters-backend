require 'rails_helper'

RSpec.describe "api/v1/children/show.json.jbuilder", type: :view do
  let(:child) do
    create(:managed_user,
      name: 'Sophie',
      birthday: Date.new(2016, 4, 15),
      gender: 'female',
      city: 'Lyon'
    )
  end

  before do
    assign(:child, child)
    render
  end

  it 'renders child wrapped in child key' do
    result = JSON.parse(rendered)
    expect(result).to have_key('child')
    expect(result['child']).to be_a(Hash)
  end

  it 'renders child using the user partial' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data['id']).to eq(child.id)
    expect(child_data['name']).to eq('Sophie')
    expect(child_data['birthday']).to eq('2016-04-15')
  end

  it 'includes managed account attributes' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data['account_type']).to eq('managed')
    expect(child_data['parent_id']).to eq(child.parent_id)
    expect(child_data['parent_id']).not_to be_nil
  end

  it 'includes all user attributes from partial' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data).to include(
      'id', 'name', 'birthday', 'gender', 'city', 'account_type', 'parent_id'
    )
  end
end
