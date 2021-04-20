# module for handling platform requests
module OpenLrw
  # OpenLrw::LrwAccessToken.new('https://example.com/').call
  class LrwAccessToken
    def initialize(base_url = nil)
      @base_url = base_url ? base_url : Rails.configuration.caliper_store['base_url']
    end

    def call
      request = make_request
      response = JSON.parse(request.body)
      response['token']
    end

    def make_request
      conn = Faraday.new(url: access_token_url)
      conn.post do |request|
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-Requested-With'] = 'XMLHttpRequest'
        request.body = {
          username: Rails.configuration.caliper_store['api_username'],
          password: Rails.configuration.caliper_store['api_password']
        }.to_json
      end
    end

    def access_token_url
      [@base_url, 'api/auth/login'].join('')
    end
  end
end
