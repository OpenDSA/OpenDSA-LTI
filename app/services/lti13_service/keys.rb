# module for handling platform requests
module Lti13Service
    # class fetch platform keys
    class Keys
      def initialize(lms_instance)
        @lms_instance = lms_instance
      end
  
      def call
        Rails.application.executor.wrap { Faraday.new(url: @lms_instance.keyset_url).get }
      end
    end
  end