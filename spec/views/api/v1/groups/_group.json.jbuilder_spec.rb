require 'rails_helper'

RSpec.describe "api/v1/groups/_group.json.jbuilder", type: :view do
  include Pundit::Authorization

  # Helper pour définir policy sur view
  def setup_policy_for_view(current_user)
    def view.policy(record)
      Pundit.policy(@current_user, record)
    end
  end

  context 'with member user' do
    let(:group) { create(:group, name: 'Partial Test Group', description: 'Partial Description') }
    let(:user) { create(:user) }

    before do
      group.add_user(user, 'member')
      assign(:current_user, user)
      setup_policy_for_view(user)
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
      expect(result.keys).to contain_exactly('id', 'name', 'description', 'members_count', 'permissions')
    end

    it 'includes permissions object' do
      result = JSON.parse(rendered)
      expect(result).to have_key('permissions')
      expect(result['permissions']).to be_a(Hash)
      expect(result['permissions']).to include('can_administer', 'is_direct_admin', 'is_member')
    end

    it 'sets correct permissions for member user' do
      result = JSON.parse(rendered)
      permissions = result['permissions']
      # user est membre mais pas admin
      expect(permissions['can_administer']).to be false
      expect(permissions['is_direct_admin']).to be false
      expect(permissions['is_member']).to be true
    end
  end

  context 'with admin user' do
    let(:admin_user) { create(:user) }
    let(:admin_group) { create(:group, name: 'Admin Group', description: 'Admin Description') }

    before do
      admin_group.add_user(admin_user, 'admin')
      assign(:current_user, admin_user)
      setup_policy_for_view(admin_user)
      render partial: 'api/v1/groups/group', locals: { group: admin_group }
    end

    it 'sets correct permissions for admin user' do
      result = JSON.parse(rendered)
      permissions = result['permissions']
      expect(permissions['can_administer']).to be true
      expect(permissions['is_direct_admin']).to be true
      expect(permissions['is_member']).to be true
    end
  end
end
