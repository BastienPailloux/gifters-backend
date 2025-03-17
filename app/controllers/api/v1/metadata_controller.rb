module Api
  module V1
    class MetadataController < Api::V1::BaseController
      # TODO: SCRAPING_FEATURE - Ce contrôleur est temporairement désactivé côté frontend
      # en raison de problèmes de scraping (timeouts, CORS, blocage par certains sites).
      # Le code est maintenu en place pour une utilisation future lorsque ces problèmes
      # seront résolus.

      require 'open-uri'
      require 'nokogiri'
      require 'uri'
      require 'timeout'
      require 'open_uri_redirections'

      # Maximum time to wait for a URL response
      URL_TIMEOUT = 10 # secondes (augmenté pour les sites lents)

      # Maximum redirects to follow
      MAX_REDIRECTS = 3

      # Maximum number of retry attempts
      MAX_RETRIES = 2

      # Delay between retries in seconds
      RETRY_DELAY = 1

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
          # Extraire le code HTTP et le message
          code, message = e.message.split(' ', 2)
          code = code.to_i

          # Log détaillé
          Rails.logger.error("HTTP Error #{code} when fetching metadata for #{url}: #{message}")

          # Réponse adaptée au code d'erreur
          case code
          when 403
            render json: { error: "Access forbidden (403). This website may block web scraping." }, status: :forbidden
          when 404
            render json: { error: "Page not found (404). The URL might be invalid." }, status: :not_found
          when 429
            render json: { error: "Too many requests (429). The website has rate-limited our requests." }, status: :too_many_requests
          when 500..599
            render json: { error: "Remote server error (#{code}). The website is experiencing issues." }, status: :bad_gateway
          else
            render json: { error: "HTTP Error: #{e.message}" }, status: :bad_gateway
          end
        rescue => e
          # Log l'erreur réelle mais ne pas exposer les détails à l'utilisateur
          Rails.logger.error("Metadata fetch error for #{url}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
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

      def fetch_metadata(url, redirect_count = 0, retry_count = 0)
        # Vérifier le nombre de redirections
        if redirect_count >= MAX_REDIRECTS
          raise "Too many redirects"
        end

        uri = URI.parse(url)

        # Limiter aux protocoles HTTP et HTTPS
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          raise "Invalid URL protocol"
        end

        begin
          # Ouverture sécurisée de l'URL avec support des redirections
          headers = {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'Accept-Encoding' => 'gzip, deflate, br',
            'Connection' => 'keep-alive',
            'Upgrade-Insecure-Requests' => '1',
            'Sec-Fetch-Dest' => 'document',
            'Sec-Fetch-Mode' => 'navigate',
            'Sec-Fetch-Site' => 'none',
            'Sec-Fetch-User' => '?1',
            'Cache-Control' => 'max-age=0'
          }

          response = URI.open(
            url,
            {
              allow_redirections: :safe,
              ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
            }.merge(headers)
          )

          # Vérifier si nous avons atteint l'URL finale ou s'il y a encore une redirection
          if response.base_uri.to_s != url && redirect_count < MAX_REDIRECTS - 1
            return fetch_metadata(response.base_uri.to_s, redirect_count + 1, retry_count)
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
        rescue OpenURI::HTTPError, SocketError, Errno::ECONNRESET => e
          # Retenter en cas d'erreur si nous n'avons pas atteint le nombre maximum de tentatives
          if retry_count < MAX_RETRIES
            Rails.logger.info("Retrying fetch for #{url} after error: #{e.message} (attempt #{retry_count + 1}/#{MAX_RETRIES})")
            sleep RETRY_DELAY # Pause avant de réessayer
            return fetch_metadata(url, redirect_count, retry_count + 1)
          else
            # Si nous avons épuisé toutes les tentatives, relancer l'erreur
            raise
          end
        end
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
