module Lti13Service
  class DeepLinkJwt
    attr_accessor :jwt, :signed_jwt

    def initialize(launch, lms_instance, tool_launch_url, selected_content = {})
      @launch = launch
      @lms_instance = lms_instance
      @tool_launch_url = tool_launch_url
      @selected_content = selected_content.is_a?(Hash) ? selected_content : {}
      @launch_payload = launch_payload
      @jwt = {}
      generate_jwt
    end

    def call
      @signed_jwt
    end

    def generate_jwt
      @jwt[Rails.configuration.lti_claims_and_scopes['message_type']] = 'LtiDeepLinkingResponse'
      @jwt[Rails.configuration.lti_claims_and_scopes['lti_version']] = '1.3.0'
      @jwt[Rails.configuration.lti_claims_and_scopes['deployment_id']] = deployment_id
      add_security_details
      add_content_items
      add_data_claim
      add_message_and_log
      create_signed_jwt
    end

    def add_security_details
      @jwt['iss'] = @lms_instance.client_id
      @jwt['aud'] = @launch_payload['iss']
      @jwt['iat'] = Time.now.to_i
      @jwt['exp'] = Time.now.to_i + 300
      @jwt['nonce'] = SecureRandom.hex(10)
    end

    def add_content_items
      @jwt[Rails.configuration.lti_claims_and_scopes['content_item_claim']] = [build_content_item]
    end

    def add_data_claim
      deep_linking_claim = Rails.configuration.lti_claims_and_scopes['deep_linking_claim']
      deep_linking_data_claim = Rails.configuration.lti_claims_and_scopes['deep_linking_data_claim']

      data = @launch_payload[deep_linking_data_claim]
      if data.blank?
        settings = @launch_payload[deep_linking_claim]
        settings = settings.is_a?(Hash) ? settings : {}
        return_url = settings['deep_link_return_url']
        if return_url.present?
          parsed = URI.parse(return_url)
          params = URI.decode_www_form(parsed.query || '')
          data_value = params.assoc('data')&.last
          data = data_value if data_value.present?
        end
      end

      @jwt[deep_linking_data_claim] = data if data.present?
    end

    def add_message_and_log
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_msg_claim']] = "Successfully added Content Item from OpenDSA"
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_log_claim']] = "OpenDSA content item: #{@selected_content.to_s}"
    end

    def create_signed_jwt
      @signed_jwt = Jwt::Encode.new(@jwt, @lms_instance.openssl_private_key).call
    end

    private

    def launch_payload
      dj = @launch.decoded_jwt
      if dj.is_a?(String)
        dj = JSON.parse(dj) rescue nil
      end
      dj.is_a?(Array) ? dj.first : dj
    end

    def deployment_id
      @launch_payload[Rails.configuration.lti_claims_and_scopes['deployment_id']]
    end

    # Build a single ltiResourceLink content item from the structured
    # selected_content hash.
    def build_content_item
      if @selected_content['moduleInfo'].present?
        build_module_item
      elsif @selected_content['exerciseInfo'].present?
        build_exercise_item
      else
        {
          type: 'ltiResourceLink',
          id: SecureRandom.hex(8),
          title: 'OpenDSA Module',
          url: @tool_launch_url,
          placementAdvice: { presentationDocumentTarget: 'iframe' }
        }
      end
    end

    def build_module_item
      info = @selected_content['moduleInfo'] || {}
      settings = @selected_content['moduleSettings'] || {}
      is_gradable = @selected_content['isGradable']
      points = settings['points']

      title = "OpenDSA: #{info['name']}"
      launch_url_with_params, custom_params = build_module_url_and_custom(info)

      item = {
        type: 'ltiResourceLink',
        id: SecureRandom.hex(8),
        title: title,
        url: launch_url_with_params,
        presentationAdvice: { presentationDocumentTarget: 'iframe' },
        custom: custom_params
      }
      if is_gradable && points.present?
        item[:lineItem] = {
          scoreMaximum: points.to_f
        }
      end
      item
    end

    def build_exercise_item
      info = @selected_content['exerciseInfo'] || {}
      settings = @selected_content['exerciseSettings'] || {}
      is_gradable = @selected_content['isGradable']
      points = settings['points'] || 1

      title = "OpenDSA: #{info['name']}"
      short_name = info['short_name']
      launch_url_with_params = "#{@tool_launch_url}?custom_ex_short_name=#{CGI.escape(short_name.to_s)}&custom_ex_settings=#{CGI.escape(settings.to_json)}"
      custom_params = {
        ex_short_name: short_name.to_s,
        ex_settings: settings.to_json
      }

      item = {
        type: 'ltiResourceLink',
        id: SecureRandom.hex(8),
        title: title,
        url: launch_url_with_params,
        presentationAdvice: { presentationDocumentTarget: 'iframe' },
        custom: custom_params
      }
      if is_gradable
        item[:lineItem] = {
          scoreMaximum: points.to_f
        }
      end
      item
    end

    def build_module_url_and_custom(info)
      inst_module_id = info['id']
      path = info['path'].to_s
      name = info['name'].to_s

      query = "custom_inst_module_id=#{CGI.escape(inst_module_id.to_s)}"
      launch_url = "#{@tool_launch_url}?#{query}"

      custom_params = {
        inst_module_id: inst_module_id.to_s,
        module_path: path.to_s,
        module_name: name.to_s
      }
      [launch_url, custom_params]
    end
  end
end
