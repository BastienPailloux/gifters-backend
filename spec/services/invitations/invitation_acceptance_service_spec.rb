require 'rails_helper'

RSpec.describe Invitations::InvitationAcceptanceService do
  let(:group) { create(:group) }
  let(:admin_user) { create(:user) }
  let(:invitation) { create(:invitation, group: group, created_by: admin_user, role: 'member') }
  let(:current_user) { create(:user) }
  let(:service) { described_class.new }

  before do
    group.add_user(admin_user, 'admin')
  end

  describe '#call' do
    context 'with valid parameters for single user' do
      let(:params) do
        {
          invitation: invitation,
          current_user: current_user,
          user_ids: [current_user.id]
        }
      end

      it 'returns success' do
        result = service.call(params)
        expect(result).to be_success
      end

      it 'creates a membership' do
        expect {
          service.call(params)
        }.to change { group.users.count }.by(1)
      end

      it 'returns proper response structure' do
        result = service.call(params)
        response = result.value!

        expect(response[:success]).to be true
        expect(response[:results].size).to eq(1)
        expect(response[:results][0][:user_id]).to eq(current_user.id)
        expect(response[:group]).to be_present
        expect(response[:group]['id']).to eq(group.id)
      end

      it 'sends a notification email' do
        expect {
          service.call(params)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'with valid parameters for parent and children' do
      let(:parent) { create(:user) }
      let(:child1) { create(:user, parent: parent, account_type: 'managed') }
      let(:child2) { create(:user, parent: parent, account_type: 'managed') }
      let(:params) do
        {
          invitation: invitation,
          current_user: parent,
          user_ids: [parent.id, child1.id, child2.id]
        }
      end

      it 'returns success' do
        result = service.call(params)
        expect(result).to be_success
      end

      it 'creates memberships for all users' do
        expect {
          service.call(params)
        }.to change { group.users.count }.by(3)

        expect(group.users).to include(parent, child1, child2)
      end

      it 'returns proper response with all users' do
        result = service.call(params)
        response = result.value!

        expect(response[:success]).to be true
        expect(response[:results].size).to eq(3)
        expect(response[:message]).to eq('3 user(s) successfully joined the group')
      end

      it 'sends notification emails for each user' do
        expect {
          service.call(params)
        }.to change { ActionMailer::Base.deliveries.count }.by(3)
      end
    end

    context 'when parent tries to add unauthorized user' do
      let(:parent) { create(:user) }
      let(:other_user) { create(:user) }
      let(:params) do
        {
          invitation: invitation,
          current_user: parent,
          user_ids: [parent.id, other_user.id]
        }
      end

      it 'adds parent but not unauthorized user' do
        result = service.call(params)
        response = result.value!

        expect(response[:success]).to be true
        expect(response[:results].size).to eq(1)
        expect(response[:results][0][:user_id]).to eq(parent.id)
        expect(response[:errors].size).to eq(1)
        expect(response[:errors][0][:error]).to eq('Not authorized to add this user')
      end
    end

    context 'when user is already a member' do
      let(:params) do
        {
          invitation: invitation,
          current_user: current_user,
          user_ids: [current_user.id]
        }
      end

      before do
        group.add_user(current_user, 'member')
      end

      it 'returns failure' do
        result = service.call(params)
        expect(result).to be_failure
      end

      it 'includes error message' do
        result = service.call(params)
        failure = result.failure

        expect(failure[:message]).to eq('No users were added to the group')
        expect(failure[:errors][0][:error]).to eq('Already a member of this group')
      end
    end

    context 'with invalid parameters' do
      context 'when invitation is missing' do
        let(:params) do
          {
            invitation: nil,
            current_user: current_user,
            user_ids: [current_user.id]
          }
        end

        it 'returns failure with validation error' do
          result = service.call(params)
          expect(result).to be_failure

          failure = result.failure
          expect(failure[:message]).to eq('Validation failed')
          expect(failure[:errors]).to have_key(:invitation)
        end
      end

      context 'when current_user is missing' do
        let(:params) do
          {
            invitation: invitation,
            current_user: nil,
            user_ids: [1]
          }
        end

        it 'returns failure with validation error' do
          result = service.call(params)
          expect(result).to be_failure

          failure = result.failure
          expect(failure[:message]).to eq('Validation failed')
          expect(failure[:errors]).to have_key(:current_user)
        end
      end

      context 'when user_ids is empty' do
        let(:params) do
          {
            invitation: invitation,
            current_user: current_user,
            user_ids: []
          }
        end

        it 'returns failure with validation error' do
          result = service.call(params)
          expect(result).to be_failure

          failure = result.failure
          expect(failure[:message]).to eq('Validation failed')
          expect(failure[:errors]).to have_key(:user_ids)
        end
      end
    end

    context 'partial success scenario' do
      let(:parent) { create(:user) }
      let(:child1) { create(:user, parent: parent, account_type: 'managed') }
      let(:child2) { create(:user, parent: parent, account_type: 'managed') }
      let(:params) do
        {
          invitation: invitation,
          current_user: parent,
          user_ids: [parent.id, child1.id, child2.id]
        }
      end

      before do
        # child1 est déjà membre
        group.add_user(child1, 'member')
      end

      it 'adds users who are not already members' do
        result = service.call(params)
        response = result.value!

        expect(response[:success]).to be true
        expect(response[:results].size).to eq(2) # parent et child2
        expect(response[:errors].size).to eq(1) # child1 déjà membre
      end
    end
  end
end
