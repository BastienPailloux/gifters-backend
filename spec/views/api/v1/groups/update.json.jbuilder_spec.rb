require 'rails_helper'

RSpec.describe "api/v1/groups/update.json.jbuilder", type: :view do
  let(:group) { create(:group, name: 'Updated Group', description: 'Updated Description') }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before do
    group.add_user(user1, 'admin')
    group.add_user(user2, 'member')
    assign(:group, group)
    render
  end

  it 'renders the updated group using the partial' do
    result = JSON.parse(rendered)
    expect(result).to include('id', 'name', 'description', 'members_count')
  end

  it 'renders correct updated group data' do
    result = JSON.parse(rendered)
    expect(result['id']).to eq(group.id)
    expect(result['name']).to eq('Updated Group')
    expect(result['description']).to eq('Updated Description')
    expect(result['members_count']).to eq(2)
  end
end
