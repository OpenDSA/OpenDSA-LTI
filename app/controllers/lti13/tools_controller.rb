class Lti13::ToolsController < ApplicationController
  before_action :set_lms_instance, only: [:jwks]

  # GET /lti13/.well-known/jwks
  # GET /lti13/.well-known/jwks/:lms_instance_id
  #
  # The unparameterized form (/lti13/.well-known/jwks) exposes the public
  # keys of ALL LTI 1.3 LmsInstances. This is intentional for multi-tenant
  # key discovery (platforms need to find the tool's key by `kid` without
  # knowing the lms_instance_id up front), but it does disclose the set of
  # configured tenants. Worth a periodic security review.
  def jwks
    Rails.logger.info "ToolsController#jwks: Generating JWKS"

    if @lms_instance
      begin
        private_key = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
        public_key = private_key.public_key
        jwk = JWT::JWK.new(public_key)
        render json: { keys: [jwk.export] }
      rescue => e
        Rails.logger.error "Error generating JWKS: #{e.message}"
        render json: { error: 'Error generating JWKS' }, status: :internal_server_error
      end
    else
      keys = all_lti13_jwks
      if keys.empty?
        render json: { error: 'LMS Instance not found' }, status: :not_found
      else
        render json: { keys: keys }
      end
    end
  end

  #~ Private methods ..........................................................

  private

  def set_lms_instance
    lms_instance_id = params[:lms_instance_id] || session[:lms_instance_id]
    @lms_instance = LmsInstance.find_by(id: lms_instance_id)
  end

  def all_lti13_jwks
    keys = []
    LmsInstance.where.not(private_key: nil).where.not(client_id: nil).find_each do |inst|
      begin
        private_key = OpenSSL::PKey::RSA.new(inst.private_key)
        jwk = JWT::JWK.new(private_key.public_key).export
        jwk['alg'] = 'RS256'
        jwk['use'] = 'sig'
        keys << jwk
      rescue => e
        Rails.logger.error "Error generating JWK for LmsInstance #{inst.id}: #{e.message}"
      end
    end
    keys
  end

end
