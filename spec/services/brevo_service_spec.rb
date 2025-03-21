require 'rails_helper'

RSpec.describe BrevoService do
  describe '.subscribe_contact' do
    let(:email) { 'test@example.com' }
    let(:list_id) { '123' }
    let(:redirect_url) { 'https://example.com/redirect' }
    let(:api_instance) { instance_double(Brevo::ContactsApi) }

    before do
      allow(Brevo::ContactsApi).to receive(:new).and_return(api_instance)
      allow(api_instance).to receive(:create_contact)
    end

    it 'calls Brevo API to create a contact' do
      expect(api_instance).to receive(:create_contact) do |contact|
        expect(contact.email).to eq(email)
        expect(contact.list_ids).to eq([list_id.to_i])
        expect(contact.update_enabled).to be true
      end

      result = BrevoService.subscribe_contact(email, list_id, redirect_url)
      expect(result).to eq({ success: true })
    end

    it 'uses default list_id from environment if none provided' do
      default_list_id = '456'
      allow(ENV).to receive(:[]).with('BREVO_LIST_ID').and_return(default_list_id)

      expect(api_instance).to receive(:create_contact) do |contact|
        expect(contact.list_ids).to eq([default_list_id.to_i])
      end

      BrevoService.subscribe_contact(email)
    end

    context 'when API raises an error' do
      it 'handles Brevo::ApiError and returns error details' do
        response_body = '{"message": "API error occurred"}'
        api_error = Brevo::ApiError.new(response_body: response_body)

        allow(api_instance).to receive(:create_contact).and_raise(api_error)

        result = BrevoService.subscribe_contact(email, list_id)
        expect(result).to eq({ success: false, error: "API error occurred" })
      end

      it 'handles general exceptions' do
        allow(api_instance).to receive(:create_contact).and_raise(StandardError.new("General error"))

        result = BrevoService.subscribe_contact(email, list_id)
        expect(result).to eq({ success: false, error: "General error" })
      end
    end
  end

  describe '.unsubscribe_contact' do
    let(:email) { 'test@example.com' }
    let(:list_id) { '123' }
    let(:api_instance) { instance_double(Brevo::ContactsApi) }

    before do
      allow(Brevo::ContactsApi).to receive(:new).and_return(api_instance)
      allow(api_instance).to receive(:remove_contact_from_list)
    end

    it 'calls Brevo API to remove a contact from list' do
      expect(api_instance).to receive(:remove_contact_from_list) do |id, remove_contact|
        expect(id).to eq(list_id.to_i)
        expect(remove_contact.emails).to eq([email])
      end

      result = BrevoService.unsubscribe_contact(email, list_id)
      expect(result).to eq({ success: true })
    end

    it 'uses default list_id from environment if none provided' do
      default_list_id = '456'
      allow(ENV).to receive(:[]).with('BREVO_LIST_ID').and_return(default_list_id)

      expect(api_instance).to receive(:remove_contact_from_list) do |id, _|
        expect(id).to eq(default_list_id.to_i)
      end

      BrevoService.unsubscribe_contact(email)
    end

    context 'when API raises an error' do
      it 'handles Brevo::ApiError and returns error details' do
        response_body = '{"message": "API error occurred"}'
        api_error = Brevo::ApiError.new(response_body: response_body)

        allow(api_instance).to receive(:remove_contact_from_list).and_raise(api_error)

        result = BrevoService.unsubscribe_contact(email, list_id)
        expect(result).to eq({ success: false, error: "API error occurred" })
      end

      it 'handles general exceptions' do
        allow(api_instance).to receive(:remove_contact_from_list).and_raise(StandardError.new("General error"))

        result = BrevoService.unsubscribe_contact(email, list_id)
        expect(result).to eq({ success: false, error: "General error" })
      end
    end
  end
end
