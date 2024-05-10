module Lti13Service
  class Keys
    def initialize(keyset_url)
      @keyset_url = keyset_url
      puts "Initialized with Keyset URL: #{@keyset_url}"
    end

    def call
      return if @keyset_url.blank?

      conn = Faraday.new(url: @keyset_url) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
      end

      response = Rails.application.executor.wrap { conn.get }
      if response.success?
        puts "Keys fetched successfully: #{response.body}"
        return JSON.parse(response.body)
      else
        puts "Error fetching keys: #{response.status} - #{response.body}"
        return nil
      end
    rescue Faraday::Error => e
      puts "Faraday encountered an error: #{e.message}"
      return nil
    end
  end
end