require 'rails_helper'

RSpec.describe Group, type: :model do
  it { should have_many(:memberships).dependent(:destroy) }
  it { should have_many(:users).through(:memberships) }
  it { should have_many(:invitations).dependent(:destroy) }

  it { should validate_presence_of(:name) }

  describe "#add_user" do
    it "creates a membership with the specified role" do
      group = create(:group)
      user = create(:user)

      # Vérifier qu'on peut ajouter un membre
      membership = group.add_user(user)
      expect(membership).to be_persisted
      expect(membership.role).to eq('member')

      # Vérifier qu'on peut ajouter un admin
      admin_membership = group.add_user(user, 'admin')
      expect(admin_membership).to be_persisted
      expect(admin_membership.role).to eq('admin')
    end
  end

  describe "#admin_users" do
    it "returns only admin users" do
      group = create(:group)
      admin1 = create(:user)
      admin2 = create(:user)
      member = create(:user)

      create(:membership, user: admin1, group: group, role: 'admin')
      create(:membership, user: admin2, group: group, role: 'admin')
      create(:membership, user: member, group: group, role: 'member')

      expect(group.admin_users).to include(admin1, admin2)
      expect(group.admin_users).not_to include(member)
    end
  end

  describe "#admin_count" do
    it "returns the count of admin users" do
      group = create(:group)
      create_list(:membership, 2, group: group, role: 'admin')
      create_list(:membership, 3, group: group, role: 'member')

      expect(group.admin_count).to eq(2)
    end
  end

  describe "#members_count" do
    it "returns the total count of all members (both admins and regular members)" do
      group = create(:group)
      create_list(:membership, 2, group: group, role: 'admin')
      create_list(:membership, 3, group: group, role: 'member')

      expect(group.members_count).to eq(5)
    end

    it "returns zero when the group has no members" do
      group = create(:group)
      # Ne pas créer de membres

      expect(group.members_count).to eq(0)
    end
  end

  describe "#create_invitation" do
    it "creates an invitation with the specified role" do
      group = create(:group)
      user = create(:user)

      # Vérifier qu'on peut créer une invitation pour un membre
      invitation = group.create_invitation(user)
      expect(invitation).to be_persisted
      expect(invitation.role).to eq('member')

      # Vérifier qu'on peut créer une invitation pour un admin
      admin_invitation = group.create_invitation(user, 'admin')
      expect(admin_invitation).to be_persisted
      expect(admin_invitation.role).to eq('admin')
    end
  end
end
