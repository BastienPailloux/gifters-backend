require 'rails_helper'

RSpec.describe "api/v1/groups/show.json.jbuilder", type: :view do
  let(:user1) { create(:user, name: 'User 1', email: 'user1@example.com') }
  let(:user2) { create(:user, name: 'User 2', email: 'user2@example.com') }
  let(:group) { create(:group, name: 'Test Group', description: 'Test Description') }

  before do
    group.add_user(user1, 'admin')
    group.add_user(user2, 'member')
    assign(:group, group)
    assign(:memberships, group.memberships.includes(:user))
    render
  end

  it 'renders group information' do
    result = JSON.parse(rendered)
    expect(result).to include('id', 'name', 'description', 'members_count')
  end

  it 'renders correct group data' do
    result = JSON.parse(rendered)
    expect(result['id']).to eq(group.id)
    expect(result['name']).to eq('Test Group')
    expect(result['description']).to eq('Test Description')
    expect(result['members_count']).to eq(2)
  end

  it 'includes members array' do
    result = JSON.parse(rendered)
    expect(result).to have_key('members')
    expect(result['members']).to be_an(Array)
    expect(result['members'].size).to eq(2)
  end

  it 'includes member details with roles' do
    result = JSON.parse(rendered)
    members = result['members']

    admin = members.find { |m| m['email'] == 'user1@example.com' }
    member = members.find { |m| m['email'] == 'user2@example.com' }

    expect(admin).to include('id', 'name', 'email', 'role')
    expect(admin['role']).to eq('admin')
    expect(admin['name']).to eq('User 1')

    expect(member).to include('id', 'name', 'email', 'role')
    expect(member['role']).to eq('member')
    expect(member['name']).to eq('User 2')
  end
end
