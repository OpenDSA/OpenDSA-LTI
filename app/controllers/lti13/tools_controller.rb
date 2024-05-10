class Lti13::ToolsController < ApplicationController
  before_action :set_lms_instance, only: [:jwks]
  
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
      render json: { error: 'LMS Instance not found' }, status: :not_found
    end
  end

  private
    
    def set_lms_instance # Use callbacks to share common setup or constraints between actions.
      # Example logic to set @lms_instance based on your application's logic
      lms_instance_id = params[:lms_instance_id] || session[:lms_instance_id]
      @lms_instance = LmsInstance.find_by(id: lms_instance_id)
    end

    # Only allowing a list of trusted parameters through.
    def tool_params
      params.require(:tool).permit(:name, :client_id, :deployment_id, :private_key, :keyset_url, :oauth2_url, :platform_oidc_auth_url)
    end
end

