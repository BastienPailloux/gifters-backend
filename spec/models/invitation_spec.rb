require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "validations" do
    # Tests personnalisés pour le token
    it "requires a token" do
      # Désactiver temporairement le callback
      allow_any_instance_of(Invitation).to receive(:generate_token)
      invitation = build(:invitation, token: nil)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:token]).to include("can't be blank")
    end

    it "validates uniqueness of token" do
      # Créer une invitation avec un token spécifique
      create(:invitation, token: "unique_token")

      # Tenter de créer une autre invitation avec le même token
      duplicate = build(:invitation, token: "unique_token")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include("has already been taken")
    end

    # Tests shoulda-matchers pour les autres attributs
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(Invitation::ROLES) }
  end

  describe "associations" do
    it { should belong_to(:group) }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe "callbacks" do
    it "generates a token before validation on create" do
      invitation = build(:invitation, token: nil)
      expect(invitation.token).to be_nil
      invitation.validate
      expect(invitation.token).not_to be_nil
      expect(invitation.token.size).to eq(22) # La taille du token généré par SecureRandom.urlsafe_base64(16)
    end

    it "does not overwrite an existing token" do
      invitation = build(:invitation, token: "custom_token")
      invitation.validate
      expect(invitation.token).to eq("custom_token")
    end
  end

  describe "#invitation_url" do
    it "returns a valid URL containing the invitation token" do
      # Configurer les options d'URL pour les tests
      allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return({ host: "example.com" })

      # Créer une invitation avec un token spécifique
      invitation = create(:invitation, token: "test_token")

      # Vérifier que l'URL contient le token
      expect(invitation.invitation_url).to include("token=test_token")

      # Vérifier que l'URL utilise le host configuré
      expect(invitation.invitation_url).to include("example.com")

      # Vérifier que l'URL contient le chemin correct
      expect(invitation.invitation_url).to include("/api/v1/invitations/accept")
    end

    it "builds URL with default options when no mailer configuration is present" do
      # Simuler l'absence de configuration pour les URL
      allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return(nil)

      invitation = create(:invitation, token: "test_token_123")

      # Simuler le comportement de URL helpers sans configuration
      allow(Rails.application.routes.url_helpers).to receive(:accept_api_v1_invitations_url)
        .with(hash_including(token: "test_token_123"))
        .and_return("http://example.com/api/v1/invitations/accept?token=test_token_123")

      # Appeler la méthode
      url = invitation.invitation_url

      # Vérifier que l'URL contient le token
      expect(url).to include("token=test_token_123")
    end
  end
end
