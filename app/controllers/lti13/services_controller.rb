class Lti13::ServicesController < ApplicationController

  # POST /send_score?launch_id=1&access_token=ABC&platform_jwt=xx&kid=xxx&highest_score
  def send_score
    result = Lti13Service::SendScore.new(
      launch_id: params[:launch_id],
      access_token: params[:access_token],
      platform_jwt: params[:platform_jwt],
      kid: params[:kid],
      highest_score: params[:highest_score]
    ).call
    render json: result.except(:status), status: result[:status] || :ok
  end

  # POST /request_names_and_roles?launch_id=1&access_token=ABC
  def request_names_and_roles
    result = Lti13Service::RequestNamesAndRoles.new(
      launch_id: params[:launch_id],
      access_token: params[:access_token],
      platform_jwt: params[:platform_jwt],
      kid: params[:kid]
    ).call
    render json: result.except(:status), status: result[:status] || :ok
  end
end
