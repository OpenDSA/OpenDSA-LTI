module Lti13::LoginInitiationsHelper
  def build_auth_url(lms_instance, state, params, nonce)
    uri = URI.parse(lms_instance.platform_oidc_auth_url)
    uri_params = Rack::Utils.parse_query(uri.query)
    auth_params = {
      response_type: 'id_token',
      redirect_uri: redirect_uri_location(lms_instance, params[:target_link_uri]),
      response_mode: 'form_post',
      client_id: lms_instance.client_id,
      scope: 'openid',
      state: state,
      login_hint: params[:login_hint],
      prompt: 'none',
      lti_message_hint: params[:lti_message_hint],
      nonce: nonce
    }.merge(uri_params)
    uri.fragment = uri.query = nil
    [uri.to_s, '?', auth_params.to_query].join
  end

  def redirect_uri_location(lms_instance, target_link_uri)
    # if target_link_uri == lti_tool_deep_link_launches_url(lms_instance)
    #   lti_tool_deep_link_launches_url(lms_instance)
    # else
    #   lti_tool_launches_url(lms_instance)
    # end
    lti13_launches_url
  end
end
