class StudentExtensionsController < ApplicationController
  load_and_authorize_resource

  # -------------------------------------------------------------
  # POST /api/student_extensions
  # External API endpoint for adding student extensions
  def external_create
    begin
      # Validate required parameters
      unless params[:user_id] && params[:inst_chapter_module_id]
        return render json: { 
          status: 'error', 
          message: 'Missing required parameters: user_id and inst_chapter_module_id' 
        }, status: :bad_request
      end

      # Find the user and module
      user = User.find_by(id: params[:user_id])
      unless user
        return render json: { 
          status: 'error', 
          message: "User not found with id: #{params[:user_id]}" 
        }, status: :not_found
      end

      inst_chapter_module = InstChapterModule.find_by(id: params[:inst_chapter_module_id])
      unless inst_chapter_module
        return render json: { 
          status: 'error', 
          message: "Module not found with id: #{params[:inst_chapter_module_id]}" 
        }, status: :not_found
      end

      # Prepare extension options
      extension_opts = {
        open_deadline: parse_datetime(params[:open_deadline]),
        due_deadline: parse_datetime(params[:due_deadline]),
        close_deadline: parse_datetime(params[:close_deadline]),
        time_limit: params[:time_limit]&.to_i
      }.compact

      # Create or update the extension
      extension = StudentExtension.create_or_update!(user, inst_chapter_module, extension_opts)

      render json: {
        status: 'success',
        message: 'Student extension created/updated successfully',
        data: {
          id: extension.id,
          user_id: extension.user_id,
          inst_chapter_module_id: extension.inst_chapter_module_id,
          open_deadline: extension.open_deadline&.iso8601,
          due_deadline: extension.due_deadline&.iso8601,
          close_deadline: extension.close_deadline&.iso8601,
          time_limit: extension.time_limit,
          created_at: extension.created_at.iso8601,
          updated_at: extension.updated_at.iso8601
        }
      }, status: :ok

    rescue ActiveRecord::RecordInvalid => e
      render json: { 
        status: 'error', 
        message: 'Validation failed',
        errors: e.record.errors.full_messages 
      }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "External extension creation error: #{e.message}"
      render json: { 
        status: 'error', 
        message: 'Internal server error' 
      }, status: :internal_server_error
    end
  end

  # -------------------------------------------------------------
  # POST /student_extensions
  def create
    @student_extension = StudentExtension.new(student_extension_params)
    
    if @student_extension.save
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Extension created successfully!' } }
        format.html { redirect_back(fallback_location: root_path, notice: 'Extension created successfully!') }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: @student_extension.errors.full_messages.join(', ') }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: 'Failed to create extension.') }
      end
    end
  end

  # -------------------------------------------------------------
  # PUT /student_extensions/:id
  def update
    if @student_extension.update(student_extension_params)
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Extension updated successfully!' } }
        format.html { redirect_back(fallback_location: root_path, notice: 'Extension updated successfully!') }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: @student_extension.errors.full_messages.join(', ') }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: 'Failed to update extension.') }
      end
    end
  end

  # -------------------------------------------------------------
  # DELETE /student_extensions/:id
  def destroy
    if @student_extension.destroy
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Extension removed successfully!' } }
        format.html { redirect_back(fallback_location: root_path, notice: 'Extension removed successfully!') }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Failed to remove extension.' }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: 'Failed to remove extension.') }
      end
    end
  end

  # -------------------------------------------------------------
  # POST /student_extensions/create_or_update
  def create_or_update
    user = User.find(params[:user_id])
    inst_chapter_module = InstChapterModule.find(params[:inst_chapter_module_id])
    
    extension_opts = {
      open_deadline: params[:open_deadline],
      due_deadline: params[:due_deadline],
      close_deadline: params[:close_deadline],
      time_limit: params[:time_limit]
    }.compact

    begin
      StudentExtension.create_or_update!(user, inst_chapter_module, extension_opts)
      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Extension updated successfully!' } }
        format.html { redirect_back(fallback_location: root_path, notice: 'Extension updated successfully!') }
      end
    rescue => e
      respond_to do |format|
        format.json { render json: { status: 'error', message: e.message }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: 'Failed to update extension.') }
      end
    end
  end

  private

  def student_extension_params
    params.require(:student_extension).permit(:user_id, :inst_chapter_module_id, 
                                             :open_deadline, :due_deadline, :close_deadline, :time_limit)
  end

  def parse_datetime(datetime_string)
    return nil if datetime_string.blank?
    
    begin
      DateTime.parse(datetime_string)
    rescue ArgumentError
      nil
    end
  end
end 