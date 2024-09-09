module Lti13Service
  # Handles fetching the platform's keyset required for JWT verification
  class Keys
    def initialize(keyset_url)
      @keyset_url = keyset_url
      Rails.logger.info "Initialized Keys service with Keyset URL: #{@keyset_url}"
    end

    # Fetch and return the keys from the keyset URL
    def call
      return if @keyset_url.blank?
      # Create a Faraday connection object to handle the HTTP request
      conn = Faraday.new(url: @keyset_url) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
      end
      #request to fetch the keys, wrapped in Rails executor
      response = Rails.application.executor.wrap { conn.get }

      if response.success?
        Rails.logger.info "Keys fetched successfully: #{response.body}"
        return JSON.parse(response.body)
      else
        Rails.logger.error "Error fetching keys: #{response.status} - #{response.body}"
        return nil
      end
    rescue Faraday::Error => e
      Rails.logger.error "Faraday encountered an error: #{e.message}"
      return nil
    end
  end
end