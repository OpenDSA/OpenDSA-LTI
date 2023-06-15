# module for handling tool requests
module Lti13Service
  # class fetch platform keys for decode
  # Lti13Service::ToolUseEvent.new(tool, platform_jwt).call
  # https://github.com/IMSGlobal/caliper-spec/blob/master/caliper-spec.md#toolUseEvent
  class ToolUseEvent
    def initialize(tool, launch, root_url, request_uuid)
      @tool = tool
      @launch = launch
      @jwt = @launch.decoded_jwt
      @root_url = root_url
      @request_uuid = request_uuid
      @sensor = {}
    end

    def call
      event_time = Time.now.utc
      add_top_level(event_time)
      add_actor
      add_object
      add_lti_message(event_time)
      add_session
      @sensor
    end

    def add_top_level(event_time)
      @sensor[:@context] = Rails.configuration.lti_claims_and_scopes['tool_use_caliper_context']
      @sensor[:id] = "urn:uuid:#{@jwt['nonce']}"
      @sensor[:type] = 'ToolUseEvent'
      @sensor[:action] = 'Used'
      @sensor[:eventTime] = event_time
      # TODO: update edApp
      @sensor[:edApp] = @jwt['iss']
    end

    def add_actor
      @sensor[:actor] = { id: [@root_url, 'tools/', @tool.id, '/users/', @jwt['sub']].join(''), type: 'Person' }
    end

    def add_object
      @sensor[:object] = { id: [@root_url, 'tools/', @tool.id ].join(''), type: 'SoftwareApplication' }
    end

    def add_lti_message(event_time)
      lti_message = {}
      lti_message[:id] = [@root_url, 'tools/', @tool.id, '/sessions/', federated_session].join('')
      lti_message[:type] = 'LtiSession'
      lti_message[:messageParameters] = @jwt
      lti_message[:dateCreated] = @launch.created_at
      lti_message[:startedAtTime] = event_time
      @sensor[:federatedSession] = lti_message
    end

    def add_session
      @sensor[:session] = { id: [@root_url, 'tools/', @tool.id, '/sessions/', @request_uuid].join(''), type: 'Session', startedAtTime: @launch.created_at }
    end

    def federated_session
      if @jwt.is_a?(Hash) && @jwt[Rails.configuration.lti_claims_and_scopes['caliper_claim']]
        @jwt[Rails.configuration.lti_claims_and_scopes['caliper_claim']]['caliper_federated_session_id'].split('urn:uuid:').last
      else
        [@jwt['nonce'], '-DL'].join
      end
    end
  end
end
