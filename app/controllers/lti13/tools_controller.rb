class Lti13::ToolsController < ApplicationController
  before_action :set_tool, only: [:show, :edit, :update, :destroy, :jwks]

  # GET /tools
  # GET /tools.json
  def index
    @tools = Tool.all
  end

  # GET /tools/1
  # GET /tools/1.json
  def show
    respond_to do |format|
      format.json{ render json:  { status: 200, client_assertion: Lti13Service::ClientCredentialsJwt.new(@tool).call} }
      format.html
    end
  end

  def jwks; end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/1/edit
  def edit
  end

  # POST /tools
  # POST /tools.json
  def create
    @tool = Tool.new(tool_params)

    respond_to do |format|
      if @tool.save
        format.html { redirect_to [:lti, @tool], notice: 'Tool was successfully created.' }
        format.json { render :show, status: :created, location: @tool }
      else
        format.html { render :new }
        format.json { render json: @tool.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tools/1
  # PATCH/PUT /tools/1.json
  def update
    respond_to do |format|
      if @tool.update(tool_params)
        format.html { redirect_to [:lti, @tool], notice: 'Tool was successfully updated.' }
        format.json { render :show, status: :ok, location: @tool }
      else
        format.html { render :edit }
        format.json { render json: @tool.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tools/1
  # DELETE /tools/1.json
  def destroy
    @tool.destroy
    respond_to do |format|
      format.html { redirect_to lti_tools_url, notice: 'Tool was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tool
      @lms_instance =  LmsInstance.find_by(id: params[:id])
      Rails.logger.info "@lms_instance: #{@lms_instance.attributes.inspect}"
      render json: { error: 'LMS Instance not found' }, status: :not_found unless @lms_instance
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tool_params
      params.require(:tool).permit(:client_id, :private_key, :deployment_id, :keyset_url, :oauth2_url, :platform_oidc_auth_url)
    end
end
