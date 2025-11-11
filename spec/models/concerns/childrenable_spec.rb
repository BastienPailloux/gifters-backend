require 'rails_helper'

RSpec.describe Childrenable, type: :concern do
  # Créer une classe temporaire pour tester la concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'users'
      include Childrenable
    end
  end

  let(:parent) { create(:user, account_type: 'standard') }
  let(:child1) { create(:managed_user, parent: parent, name: 'Child 1') }
  let(:child2) { create(:managed_user, parent: parent, name: 'Child 2') }
  let(:other_user) { create(:user, account_type: 'standard') }

  describe 'associations' do
    it 'has a belongs_to :parent association' do
      expect(child1.parent).to eq(parent)
    end

    it 'has a has_many :children association' do
      child1
      child2
      expect(parent.children).to include(child1, child2)
      expect(parent.children.count).to eq(2)
    end

    it 'destroys children when parent is destroyed' do
      child1
      child2
      expect { parent.destroy }.to change { User.count }.by(-3) # parent + 2 children
    end

    it 'allows parent to be optional (nil)' do
      user = create(:user, parent: nil)
      expect(user.parent).to be_nil
      expect(user).to be_valid
    end
  end

  describe 'scopes' do
    describe '.standard' do
      before do
        parent
        child1
        child2
        other_user
      end

      it 'returns only standard accounts' do
        standard_users = User.standard
        expect(standard_users).to include(parent, other_user)
        expect(standard_users).not_to include(child1, child2)
        expect(standard_users.count).to eq(2)
      end
    end

    describe '.managed' do
      before do
        parent
        child1
        child2
        other_user
      end

      it 'returns only managed accounts' do
        managed_users = User.managed
        expect(managed_users).to include(child1, child2)
        expect(managed_users).not_to include(parent, other_user)
        expect(managed_users.count).to eq(2)
      end
    end
  end

  describe '#has_children?' do
    context 'when user has children' do
      before do
        child1
        child2
      end

      it 'returns true' do
        expect(parent.has_children?).to be true
      end
    end

    context 'when user has no children' do
      it 'returns false' do
        expect(parent.has_children?).to be false
      end
    end

    context 'when user is a child' do
      before { child1 }

      it 'returns false' do
        expect(child1.has_children?).to be false
      end
    end
  end

  describe '#can_access_as_parent?' do
    before do
      child1
      child2
    end

    context 'when checking access to own child' do
      it 'returns true' do
        expect(parent.can_access_as_parent?(child1)).to be true
        expect(parent.can_access_as_parent?(child2)).to be true
      end
    end

    context 'when checking access to another user' do
      it 'returns false' do
        expect(parent.can_access_as_parent?(other_user)).to be false
      end
    end

    context "when checking access to someone else's child" do
      let(:another_parent) { create(:user) }
      let(:another_child) { create(:managed_user, parent: another_parent) }

      before { another_child }

      it 'returns false' do
        expect(parent.can_access_as_parent?(another_child)).to be false
      end
    end

    context 'when record is nil' do
      it 'returns false' do
        expect(parent.can_access_as_parent?(nil)).to be false
      end
    end

    context 'when child tries to access parent' do
      it 'returns false' do
        expect(child1.can_access_as_parent?(parent)).to be false
      end
    end

    context 'when sibling tries to access sibling' do
      it 'returns false' do
        expect(child1.can_access_as_parent?(child2)).to be false
      end
    end
  end

  describe 'integration scenarios' do
    context 'parent with multiple children' do
      let(:child3) { create(:managed_user, parent: parent, name: 'Child 3') }

      before do
        child1
        child2
        child3
      end

      it 'correctly manages all relationships' do
        expect(parent.children.count).to eq(3)
        expect(parent.has_children?).to be true
        parent.children.each do |child|
          expect(parent.can_access_as_parent?(child)).to be true
          expect(child.parent).to eq(parent)
        end
      end
    end

    context 'orphaned children (parent is nil)' do
      let(:orphan) { create(:user, account_type: 'standard', parent: nil) }

      it 'allows users without parents' do
        expect(orphan.parent).to be_nil
        expect(orphan).to be_valid
      end
    end

    context 'filtering and querying' do
      before do
        parent
        child1
        child2
        other_user
      end

      it 'can chain scopes' do
        # On peut chaîner les scopes si besoin
        managed_children = User.managed.where(parent_id: parent.id)
        expect(managed_children).to include(child1, child2)
        expect(managed_children.count).to eq(2)
      end

      it 'can find all children of a specific parent' do
        children = User.where(parent_id: parent.id)
        expect(children).to include(child1, child2)
        expect(children.count).to eq(2)
      end
    end
  end

  describe '#responsible_user' do
    it 'returns self for standard accounts' do
      user = create(:user, account_type: 'standard')
      expect(user.responsible_user).to eq(user)
    end

    it 'returns parent for managed accounts with a parent' do
      parent = create(:user)
      child = create(:user, parent: parent, account_type: 'managed')
      expect(child.responsible_user).to eq(parent)
    end

    it 'returns self for managed account without parent' do
      child = build(:user, account_type: 'managed', parent: nil)
      expect(child.responsible_user).to eq(child)
    end

    it 'can be used for email recipients' do
      parent = create(:user, email: 'parent@example.com')
      child = create(:user, parent: parent, account_type: 'managed', email: 'child@example.com')

      # L'email devrait être envoyé au parent
      expect(child.responsible_user.email).to eq('parent@example.com')
    end

    it 'can be used for audit trails' do
      parent = create(:user, name: 'Parent User')
      child = create(:user, parent: parent, account_type: 'managed', name: 'Child User')

      # Les actions du child devraient être attribuées au parent dans les logs
      expect(child.responsible_user.name).to eq('Parent User')
    end
  end
end
