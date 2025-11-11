require 'rails_helper'

RSpec.describe "api/v1/groups/show.json.jbuilder", type: :view do
  include Pundit::Authorization

  # Helper pour définir policy sur view
  def setup_policy_for_view(current_user)
    def view.policy(record)
      Pundit.policy(@current_user, record)
    end
  end

  context 'with admin user' do
    let(:user1) { create(:user, name: 'User 1', email: 'user1@example.com') }
    let(:user2) { create(:user, name: 'User 2', email: 'user2@example.com') }
    let(:group) { create(:group, name: 'Test Group', description: 'Test Description') }

    before do
      group.add_user(user1, 'admin')
      group.add_user(user2, 'member')
      assign(:group, group)
      assign(:memberships, group.memberships.includes(:user))
      assign(:current_user, user1)
      setup_policy_for_view(user1)

      render
    end

  it 'renders group information' do
    result = JSON.parse(rendered)
    expect(result).to include('id', 'name', 'description', 'members_count', 'permissions')
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

  it 'includes permissions object' do
    result = JSON.parse(rendered)
    expect(result).to have_key('permissions')
    expect(result['permissions']).to be_a(Hash)
    expect(result['permissions']).to include('can_administer', 'is_direct_admin', 'is_member')
  end

  it 'sets correct permissions for admin user' do
    result = JSON.parse(rendered)
    permissions = result['permissions']
    # user1 est admin direct
    expect(permissions['can_administer']).to be true
    expect(permissions['is_direct_admin']).to be true
    expect(permissions['is_member']).to be true
  end
  end

  context 'with member user' do
    let(:member_group) { create(:group, name: 'Member Group', description: 'Member Description') }
    let(:member1) { create(:user, name: 'Member 1') }
    let(:member2) { create(:user, name: 'Member 2') }

    before do
      member_group.add_user(member1, 'admin')
      member_group.add_user(member2, 'member')
      assign(:group, member_group)
      assign(:memberships, member_group.memberships.includes(:user))
      assign(:current_user, member2)
      setup_policy_for_view(member2)
      render
    end

    it 'sets correct permissions for member user' do
      result = JSON.parse(rendered)
      permissions = result['permissions']
      # member2 est membre mais pas admin
      expect(permissions['can_administer']).to be false
      expect(permissions['is_direct_admin']).to be false
      expect(permissions['is_member']).to be true
    end
  end

  context 'with parent of admin child' do
    let(:parent) { create(:user) }
    let(:child) { create(:managed_user, parent: parent) }
    let(:child_group) { create(:group) }

    before do
      child_group.add_user(child, 'admin')
      assign(:group, child_group)
      assign(:memberships, child_group.memberships.includes(:user))
      assign(:current_user, parent)
      setup_policy_for_view(parent)
      render
    end

    it 'grants admin permissions because child is admin' do
      result = JSON.parse(rendered)
      permissions = result['permissions']
      # Le parent peut administrer car son enfant est admin
      expect(permissions['can_administer']).to be true
      # Mais le parent n'est pas admin direct
      expect(permissions['is_direct_admin']).to be false
      # Et le parent n'est pas membre direct
      expect(permissions['is_member']).to be false
    end
  end
end
