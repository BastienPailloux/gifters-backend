# Service pour gérer les interactions avec l'API Brevo
class BrevoService
  class << self
    # Abonne un email à une liste Brevo
    # @param email [String] l'email à abonner
    # @param list_id [String] l'ID de la liste Brevo (optionnel)
    # @param redirect_url [String] l'URL de redirection (non utilisé, conservé pour compatibilité d'API)
    # @return [Hash] résultat de l'opération avec :success et éventuellement :error
    def subscribe_contact(email, list_id = nil, redirect_url = nil)
      list_id ||= ENV['BREVO_LIST_ID']

      begin
        # Créer un client pour l'API Contacts
        api_instance = Brevo::ContactsApi.new

        # Préparer les données du contact
        create_contact = Brevo::CreateContact.new
        create_contact.email = email
        create_contact.list_ids = [list_id.to_i]
        create_contact.update_enabled = true
        # Note: redirect_url n'est pas supporté par l'API Brevo et a été supprimé

        # Ajouter le contact à Brevo
        api_instance.create_contact(create_contact)

        { success: true }
      rescue Brevo::ApiError => e
        error_json = JSON.parse(e.response_body) rescue { message: e.message }
        Rails.logger.error("Brevo API error: #{error_json}")
        { success: false, error: error_json['message'] || e.message }
      rescue => e
        Rails.logger.error("Newsletter subscription error: #{e.message}")
        { success: false, error: e.message }
      end
    end

    # Désabonne un email d'une liste Brevo
    # @param email [String] l'email à désabonner
    # @param list_id [String] l'ID de la liste Brevo (optionnel)
    # @return [Hash] résultat de l'opération avec :success et éventuellement :error
    def unsubscribe_contact(email, list_id = nil)
      list_id ||= ENV['BREVO_LIST_ID']

      begin
        # Créer un client pour l'API Contacts
        api_instance = Brevo::ContactsApi.new

        # Rechercher le contact par email
        contacts = api_instance.get_contacts_from_list(list_id.to_i, email: email)

        if contacts.contacts.empty?
          return { success: false, error: "Email not found in list" }
        end

        # Désabonner le contact de la liste
        api_instance.remove_contact_from_list(list_id.to_i, contacts.contacts.first.id)

        { success: true }
      rescue Brevo::ApiError => e
        error_json = JSON.parse(e.response_body) rescue { message: e.message }
        Rails.logger.error("Brevo API error: #{error_json}")
        { success: false, error: error_json['message'] || e.message }
      rescue => e
        Rails.logger.error("Newsletter unsubscription error: #{e.message}")
        { success: false, error: e.message }
      end
    end
  end
end
