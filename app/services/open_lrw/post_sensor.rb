# module for handling platform requests
module OpenLrw
    # OpenLrw::PostSensor.new(base_url, sensor, data).call
    class PostSensor
      def initialize(sensor, event, base_url = nil)
        @sensor = sensor
        @event = event
        @base_url = base_url ? base_url : Rails.configuration.caliper_store['base_url']
      end
  
      def call
        return unless Rails.configuration.caliper_store['enabled'] == true
        # token = fetch_token
        token = 'lti-ri'
        make_request(token)
      end
   
      def make_request(token)
        conn = Faraday.new(url: post_sensor_url)
        response = conn.post do |request|
          request.headers['Content-Type'] = 'application/json'
          request.headers['X-Requested-With'] = 'XMLHttpRequest'
          request.headers['Authorization'] = "Bearer #{token}"
          request.body = {
            sensor: @sensor,
            sendTime: Time.now.utc,
            data: [@event]
          }.to_json
        end
      end
  
      def post_sensor_url
        [@base_url, 'api/events'].join('')
      end
  
      def fetch_token
        # OpenLrw::LrwAccessToken.new('https://example.com/').call
        # OpenLrw::LrwAccessToken.new(@base_url).call
      end
    end
  end