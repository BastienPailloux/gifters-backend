require 'rails_helper'

RSpec.describe "api/v1/children/update.json.jbuilder", type: :view do
  let(:child) do
    create(:managed_user,
      name: 'Updated Child',
      birthday: Date.new(2017, 8, 5),
      city: 'Marseille'
    )
  end

  before do
    assign(:child, child)
    render
  end

  it 'renders updated child wrapped in child key' do
    result = JSON.parse(rendered)
    expect(result).to have_key('child')
    expect(result['child']).to be_a(Hash)
  end

  it 'renders updated child using the user partial' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data['name']).to eq('Updated Child')
    expect(child_data['birthday']).to eq('2017-08-05')
    expect(child_data['city']).to eq('Marseille')
  end

  it 'includes success message' do
    result = JSON.parse(rendered)
    expect(result).to have_key('message')
    expect(result['message']).to eq('Child account updated successfully')
  end

  it 'includes managed account attributes' do
    result = JSON.parse(rendered)
    child_data = result['child']

    expect(child_data['account_type']).to eq('managed')
    expect(child_data['parent_id']).to eq(child.parent_id)
    expect(child_data['parent_id']).not_to be_nil
  end
end
