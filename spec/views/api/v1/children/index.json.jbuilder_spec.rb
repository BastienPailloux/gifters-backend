require 'rails_helper'

RSpec.describe "api/v1/children/index.json.jbuilder", type: :view do
  let(:parent) { create(:user) }
  let!(:child1) { create(:managed_user, parent: parent, name: 'Emma', birthday: Date.new(2015, 6, 10)) }
  let!(:child2) { create(:managed_user, parent: parent, name: 'Lucas', birthday: Date.new(2018, 9, 22)) }

  before do
    assign(:children, [child1, child2])
    render
  end

  it 'renders a children array' do
    result = JSON.parse(rendered)
    expect(result).to have_key('children')
    expect(result['children']).to be_an(Array)
  end

  it 'renders all children' do
    result = JSON.parse(rendered)
    expect(result['children'].size).to eq(2)
  end

  it 'renders children using the user partial' do
    result = JSON.parse(rendered)
    child_names = result['children'].map { |c| c['name'] }
    expect(child_names).to include('Emma', 'Lucas')
  end

  it 'includes full user attributes for each child' do
    result = JSON.parse(rendered)
    child = result['children'].first

    expect(child).to include(
      'id', 'name', 'birthday', 'account_type', 'parent_id'
    )
  end

  it 'renders account_type as managed for all children' do
    result = JSON.parse(rendered)
    account_types = result['children'].map { |c| c['account_type'] }
    expect(account_types).to all(eq('managed'))
  end

  it 'renders parent_id for all children' do
    result = JSON.parse(rendered)
    parent_ids = result['children'].map { |c| c['parent_id'] }
    expect(parent_ids).to all(eq(parent.id))
  end
end
