require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "contact_message" do
    let(:name) { "John Doe" }
    let(:email) { "john@example.com" }
    let(:subject) { "Contact message" }
    let(:message) { "This is a test message" }
    let(:mail) { ContactMailer.contact_message(name, email, subject, message) }

    it "renders the headers" do
      expect(mail.subject).to eq("Contact Form: #{subject}")
      expect(mail.to).to eq(["contact@gifters.fr"])
      expect(mail.from).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(name)
      expect(mail.body.encoded).to include(message)
    end
  end

end
