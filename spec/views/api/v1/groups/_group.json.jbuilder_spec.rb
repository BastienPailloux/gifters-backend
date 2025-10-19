require 'rails_helper'

RSpec.describe "api/v1/groups/_group.json.jbuilder", type: :view do
  let(:group) { create(:group, name: 'Partial Test Group', description: 'Partial Description') }
  let(:user) { create(:user) }

  before do
    group.add_user(user, 'member')
    render partial: 'api/v1/groups/group', locals: { group: group }
  end

  it 'renders group id' do
    result = JSON.parse(rendered)
    expect(result['id']).to eq(group.id)
  end

  it 'renders group name' do
    result = JSON.parse(rendered)
    expect(result['name']).to eq('Partial Test Group')
  end

  it 'renders group description' do
    result = JSON.parse(rendered)
    expect(result['description']).to eq('Partial Description')
  end

  it 'renders members_count' do
    result = JSON.parse(rendered)
    expect(result['members_count']).to eq(1)
  end

  it 'includes all required attributes' do
    result = JSON.parse(rendered)
    expect(result.keys).to contain_exactly('id', 'name', 'description', 'members_count')
  end
end
