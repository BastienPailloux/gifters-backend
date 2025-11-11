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
    it "returns a valid frontend URL containing the invitation token" do
      # Créer une invitation avec un token spécifique
      invitation = create(:invitation, token: "test_token")

      # Vérifier que l'URL contient le token
      expect(invitation.invitation_url).to include("token=test_token")

      # Vérifier que l'URL contient le chemin correct du frontend
      expect(invitation.invitation_url).to include("/invitation/join")

      # Vérifier que l'URL utilise le localhost en développement
      expect(invitation.invitation_url).to include("localhost:5173")
    end

    it "uses FRONTEND_URL environment variable when set" do
      # Simuler la variable d'environnement
      allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('https://custom-frontend.com')
      allow(ENV).to receive(:[]).and_call_original

      invitation = create(:invitation, token: "test_token_456")

      # Vérifier que l'URL utilise la variable d'environnement
      expect(invitation.invitation_url).to eq("http://localhost:5173/invitation/join?token=test_token_456")
    end

    it "uses default localhost URL in test environment" do
      invitation = create(:invitation, token: "test_token_789")

      # En environnement de test, devrait utiliser localhost:5173
      expect(invitation.invitation_url).to eq("http://localhost:5173/invitation/join?token=test_token_789")
    end
  end
end
