require 'rails_helper'

RSpec.describe "api/v1/groups/index.json.jbuilder", type: :view do
  include Pundit::Authorization

  let(:user) { create(:user, name: 'Test User') }
  let(:group1) { create(:group, name: 'Group 1', description: 'Description 1') }
  let(:group2) { create(:group, name: 'Group 2', description: 'Description 2') }

  before do
    group1.add_user(user)
    group2.add_user(user)
  end

  context 'without with_children parameter' do
    before do
      assign(:user, user)
      assign(:groups, [group1, group2])
      assign(:children, nil)
      assign(:current_user, user)
      def view.policy(record)
        Pundit.policy(@current_user, record)
      end
      render
    end

    it 'renders an array of groups' do
      result = JSON.parse(rendered)
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it 'includes all required group attributes' do
      result = JSON.parse(rendered)
      group_data = result.first

      expect(group_data).to include('id', 'name', 'description', 'members_count')
    end

    it 'renders correct group data' do
      result = JSON.parse(rendered)
      group_names = result.map { |g| g['name'] }

      expect(group_names).to include('Group 1', 'Group 2')
    end
  end

  context 'with with_children parameter' do
    let(:child1) { create(:managed_user, parent: user, name: 'Child 1') }
    let(:child2) { create(:managed_user, parent: user, name: 'Child 2') }
    let(:child_group) { create(:group, name: 'Child Group') }

    before do
      child_group.add_user(child1)
      assign(:user, user)
      assign(:groups, [group1, group2])
      assign(:children, [child1, child2])
      assign(:current_user, user)
      def view.policy(record)
        Pundit.policy(@current_user, record)
      end
      render
    end

    it 'renders a hierarchical structure' do
      result = JSON.parse(rendered)
      expect(result).to be_a(Hash)
      expect(result).to include('id', 'name', 'account_type', 'groups', 'children')
    end

    it 'includes user information' do
      result = JSON.parse(rendered)
      expect(result['id']).to eq(user.id)
      expect(result['name']).to eq('Test User')
      expect(result['account_type']).to eq('standard')
    end

    it 'includes user groups' do
      result = JSON.parse(rendered)
      expect(result['groups']).to be_an(Array)
      expect(result['groups'].size).to eq(2)
      group_names = result['groups'].map { |g| g['name'] }
      expect(group_names).to include('Group 1', 'Group 2')
    end

    it 'includes children information' do
      result = JSON.parse(rendered)
      expect(result['children']).to be_an(Array)
      expect(result['children'].size).to eq(2)
      child_names = result['children'].map { |c| c['name'] }
      expect(child_names).to include('Child 1', 'Child 2')
    end

    it 'includes groups for each child' do
      result = JSON.parse(rendered)
      child1_data = result['children'].find { |c| c['name'] == 'Child 1' }
      expect(child1_data).to have_key('groups')
      expect(child1_data['groups']).to be_an(Array)
    end
  end

  context 'with empty groups' do
    before do
      assign(:user, user)
      assign(:groups, [])
      assign(:children, nil)
      assign(:current_user, user)
      def view.policy(record)
        Pundit.policy(@current_user, record)
      end
      render
    end

    it 'renders an empty array' do
      result = JSON.parse(rendered)
      expect(result).to be_an(Array)
      expect(result).to be_empty
    end
  end
end
