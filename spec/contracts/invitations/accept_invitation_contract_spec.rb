require 'rails_helper'

RSpec.describe Invitations::AcceptInvitationContract do
  subject(:contract) { described_class.new }

  let(:invitation) { create(:invitation) }
  let(:user) { create(:user) }

  describe 'validation' do
    context 'with valid parameters' do
      let(:params) do
        {
          invitation: invitation,
          current_user: user,
          user_ids: [user.id]
        }
      end

      it 'passes validation' do
        result = contract.call(params)
        expect(result).to be_success
      end
    end

    context 'with multiple user_ids' do
      let(:params) do
        {
          invitation: invitation,
          current_user: user,
          user_ids: [1, 2, 3]
        }
      end

      it 'passes validation' do
        result = contract.call(params)
        expect(result).to be_success
      end
    end

    context 'when invitation is missing' do
      let(:params) do
        {
          current_user: user,
          user_ids: [1]
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:invitation]).to be_present
      end
    end

    context 'when invitation is not an Invitation object' do
      let(:params) do
        {
          invitation: 'not an invitation',
          current_user: user,
          user_ids: [1]
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:invitation]).to include('must be a valid Invitation')
      end
    end

    context 'when current_user is missing' do
      let(:params) do
        {
          invitation: invitation,
          user_ids: [1]
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:current_user]).to be_present
      end
    end

    context 'when current_user is not a User object' do
      let(:params) do
        {
          invitation: invitation,
          current_user: 'not a user',
          user_ids: [1]
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:current_user]).to include('must be a valid User')
      end
    end

    context 'when user_ids is empty' do
      let(:params) do
        {
          invitation: invitation,
          current_user: user,
          user_ids: []
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:user_ids]).to include('cannot be empty')
      end
    end

    context 'when user_ids contains non-integer values' do
      let(:params) do
        {
          invitation: invitation,
          current_user: user,
          user_ids: ['not', 'integers']
        }
      end

      it 'fails validation' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:user_ids]).to be_present
      end
    end

    context 'when user_ids contains negative or zero values' do
      let(:params) do
        {
          invitation: invitation,
          current_user: user,
          user_ids: [0, -1, 5]
        }
      end

      it 'fails validation for invalid IDs' do
        result = contract.call(params)
        expect(result).to be_failure
        expect(result.errors[:user_ids]).to be_present
      end
    end
  end
end
