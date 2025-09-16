class Lti13::ToolsController < ApplicationController

  # GET /tools
  def index
    @tools = Tool.all
  end

  # GET /tools/1
  def show
    @tool = Tool.find(params[:id])
  end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/1/edit
  def edit
    @tool = Tool.find(params[:id])
  end

  # POST /tools
  def create
    @tool = Tool.new(tool_params)

    if @tool.save
      redirect_to [:lti, @tool], notice: 'Tool was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tools/1
  def update
    @tool = Tool.find(params[:id])
    if @tool.update(tool_params)
      redirect_to [:lti, @tool], notice: 'Tool was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tools/1
  def destroy
    @tool = Tool.find(params[:id])
    @tool.destroy
    redirect_to lti_tools_url, notice: 'Tool was successfully destroyed.'
  end

  # GET /.well-known/jwks
  def jwks
    Rails.logger.info "ToolsController#jwks: Generating JWKS for all LMS instances"
    keys = LmsInstance.all.map do |lms_instance|
      if lms_instance.private_key.present?
        begin
          private_key = OpenSSL::PKey::RSA.new(lms_instance.private_key)
          kid = Jwt::KidFromPrivateKey.new(lms_instance.private_key).call
          public_key = private_key.public_key
          jwk = JWT::JWK.new(public_key)
          
          exported_jwk = jwk.export
          exported_jwk[:kid] = kid
          exported_jwk[:alg] = 'RS256'
          exported_jwk[:use] = 'sig'
          
          exported_jwk
        rescue => e
          Rails.logger.error "Error generating JWK for LmsInstance #{lms_instance.id}: #{e.message}"
          nil
        end
      end
    end.compact
    render json: { keys: keys }
  end

  #~ Private methods ..........................................................

  private
  # -------------------------------------------------------------

    # Only allowing a list of trusted parameters through.
  def tool_params
    params.require(:tool).permit(:name, :client_id, :deployment_id, :private_key, :keyset_url, :oauth2_url, :platform_oidc_auth_url)
  end

end