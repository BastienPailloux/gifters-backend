module Api
  module V1
    class MetadataController < Api::V1::BaseController
      require 'open-uri'
      require 'nokogiri'
      require 'uri'
      require 'timeout'

      # Maximum time to wait for a URL response
      URL_TIMEOUT = 5 # seconds

      # Maximum redirects to follow
      MAX_REDIRECTS = 3

      # POST /api/v1/metadata/fetch
      def fetch
        url = params[:url]

        # Validation de base de l'URL
        unless valid_url?(url)
          return render json: { error: 'Invalid URL format' }, status: :bad_request
        end

        begin
          # Sécuriser la requête avec un timeout
          metadata = Timeout.timeout(URL_TIMEOUT) do
            fetch_metadata(url)
          end

          render json: metadata
        rescue Timeout::Error
          render json: { error: 'Request timed out' }, status: :request_timeout
        rescue OpenURI::HTTPError => e
          render json: { error: "HTTP Error: #{e.message}" }, status: :bad_gateway
        rescue => e
          # Log l'erreur réelle mais ne pas exposer les détails à l'utilisateur
          Rails.logger.error("Metadata fetch error: #{e.message}")
          render json: { error: 'Failed to fetch metadata' }, status: :internal_server_error
        end
      end

      private

      def valid_url?(url)
        return false if url.blank?

        # Vérification du format de l'URL
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        false
      end

      def fetch_metadata(url, redirect_count = 0)
        # Vérifier le nombre de redirections
        if redirect_count >= MAX_REDIRECTS
          raise "Too many redirects"
        end

        uri = URI.parse(url)

        # Limiter aux protocoles HTTP et HTTPS
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise "Invalid URL protocol"
        end

        # Ouverture sécurisée de l'URL
        response = URI.open(
          url,
          'User-Agent' => 'Gifters/1.0', # Identifiant de notre application
          allow_redirections: :safe,      # Ne suit que les redirections HTTP vers HTTPS
          ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER # Vérifier les certificats SSL
        )

        # Suivre une redirection si nécessaire
        if response.base_uri.to_s != url
          return fetch_metadata(response.base_uri.to_s, redirect_count + 1)
        end

        # Parse le HTML
        doc = Nokogiri::HTML(response)

        # Récupérer les métadonnées
        {
          title: extract_title(doc),
          description: extract_description(doc),
          price: extract_price(doc),
          image_url: extract_image(doc, uri)
        }
      end

      def extract_title(doc)
        # Essayer d'abord les meta tags
        meta_title = doc.at_css('meta[property="og:title"]')&.attributes&.[]('content')&.value
        return meta_title if meta_title.present?

        # Ensuite le titre de la page
        doc.at_css('title')&.text
      end

      def extract_description(doc)
        # Essayer les meta tags
        meta_desc = doc.at_css('meta[property="og:description"], meta[name="description"]')&.attributes&.[]('content')&.value
        return meta_desc if meta_desc.present?

        # Prendre un extrait du premier paragraphe substantiel
        doc.css('p').each do |p|
          text = p.text.strip
          return text.truncate(200) if text.length > 50
        end

        nil
      end

      def extract_price(doc)
        # Rechercher les patterns de prix communs
        price_selectors = [
          'span[itemprop="price"]',
          'meta[property="product:price:amount"]',
          'meta[property="og:price:amount"]',
          '.price',
          '#price',
          '.product-price',
          '[data-price]'
        ]

        price_selectors.each do |selector|
          elements = doc.css(selector)
          elements.each do |element|
            # Essayer d'extraire le prix des attributs ou du texte
            price_text = element['content'] || element['data-price'] || element.text

            if price_text.present?
              # Nettoyer et extraire les chiffres et la virgule décimale
              price_match = price_text.gsub(/[^\d,.]/, '').match(/\d+[.,]?\d*/)
              if price_match
                # Convertir en float en remplaçant la virgule par un point si nécessaire
                return price_match[0].gsub(',', '.').to_f
              end
            end
          end
        end

        nil
      end

      def extract_image(doc, base_uri)
        # Essayer de trouver une image principale
        og_image = doc.at_css('meta[property="og:image"]')&.attributes&.[]('content')&.value
        return absolute_url(og_image, base_uri) if og_image.present?

        # Chercher d'autres images potentielles
        image_selectors = [
          'img[itemprop="image"]',
          '.product-image img',
          '#product-image',
          '.main-image img',
          'img.product'
        ]

        image_selectors.each do |selector|
          image = doc.at_css(selector)
          if image && image['src'].present?
            return absolute_url(image['src'], base_uri)
          end
        end

        # Prendre la première image substantielle (éviter les petites icônes)
        doc.css('img').each do |img|
          if img['src'].present? && (img['width'].nil? || img['width'].to_i > 100) && (img['height'].nil? || img['height'].to_i > 100)
            return absolute_url(img['src'], base_uri)
          end
        end

        nil
      end

      def absolute_url(url_string, base_uri)
        return nil if url_string.blank?

        begin
          # Convertir les URLs relatives en URLs absolues
          uri = URI.parse(url_string)
          return url_string if uri.absolute?

          # Construire l'URL absolue à partir de l'URL de base
          URI.join(base_uri, url_string).to_s
        rescue URI::InvalidURIError
          nil
        end
      end
    end
  end
end
