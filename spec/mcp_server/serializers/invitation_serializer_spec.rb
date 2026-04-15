# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Serializers::InvitationSerializer do
  let(:creator)    { create(:user, name: 'Alice') }
  let(:group)      { create(:group) }
  let(:invitation) { create(:invitation, group: group, created_by: creator, role: 'member') }

  describe '.serialize' do
    subject(:result) { described_class.serialize(invitation) }

    it 'retourne id, role, created_by_id, created_by_name' do
      expect(result[:id]).to eq(invitation.id)
      expect(result[:role]).to eq('member')
      expect(result[:created_by_id]).to eq(creator.id)
      expect(result[:created_by_name]).to eq('Alice')
    end

    it 'retourne invitation_url' do
      expect(result[:invitation_url]).to eq(invitation.invitation_url)
    end
  end
end
