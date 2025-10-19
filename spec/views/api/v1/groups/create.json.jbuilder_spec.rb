require 'rails_helper'

RSpec.describe "api/v1/groups/create.json.jbuilder", type: :view do
  let(:group) { create(:group, name: 'New Group', description: 'New Description') }
  let(:user) { create(:user) }

  before do
    group.add_user(user, 'admin')
    assign(:group, group)
    render
  end

  it 'renders the created group using the partial' do
    result = JSON.parse(rendered)
    expect(result).to include('id', 'name', 'description', 'members_count')
  end

  it 'renders correct group data' do
    result = JSON.parse(rendered)
    expect(result['id']).to eq(group.id)
    expect(result['name']).to eq('New Group')
    expect(result['description']).to eq('New Description')
    expect(result['members_count']).to eq(1)
  end
end
