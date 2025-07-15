class EgpBrokerController < ApplicationController
  before_action :set_student_extension, only: [:show, :update, :destroy]

  # GET /egp_broker/student_extensions
  def index
    @student_extensions = StudentExtension.all
    render json: @student_extensions
  end

  # GET /egp_broker/student_extensions/:id
  def show
    render json: @student_extension
  end

  # POST /egp_broker/student_extensions
  def create
    user = User.find_by(email: params[:student_extension][:user_email])
    unless user
      render json: { error: 'User not found with provided email' }, status: :not_found and return
    end
    inst_chapter_module = InstChapterModule.find_by(id: params[:student_extension][:inst_chapter_module_id])
    unless inst_chapter_module
      render json: { error: 'InstChapterModule not found' }, status: :not_found and return
    end

    extension_params = student_extension_params.merge(user_id: user.id)

    if params[:student_extension][:due_offset_hours]
      offset = params[:student_extension][:due_offset_hours].to_i.hours
      existing_ext = StudentExtension.find_by(user_id: user.id, inst_chapter_module_id: inst_chapter_module.id)
      base_due = existing_ext&.due_deadline || inst_chapter_module.due_dates
      base_close = existing_ext&.close_deadline || inst_chapter_module.due_dates
      extension_params[:due_deadline] = base_due ? base_due + offset : nil
      extension_params[:close_deadline] = base_close ? base_close + offset : nil
    end

    @student_extension = StudentExtension.find_or_initialize_by(user_id: user.id, inst_chapter_module_id: inst_chapter_module.id)
    if @student_extension.update(extension_params)
      render json: @student_extension, status: :ok
    else
      render json: { errors: @student_extension.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /egp_broker/student_extensions/:id
  def update
    if params[:student_extension][:user_email]
      user = User.find_by(email: params[:student_extension][:user_email])
      unless user
        render json: { error: 'User not found with provided email' }, status: :not_found and return
      end
      extension_params = student_extension_params.merge(user_id: user.id)
    else
      extension_params = student_extension_params
    end

    if params[:student_extension][:due_offset_hours]
      offset = params[:student_extension][:due_offset_hours].to_i.hours
      inst_chapter_module = InstChapterModule.find_by(id: params[:student_extension][:inst_chapter_module_id] || @student_extension.inst_chapter_module_id)
      base_due = @student_extension.due_deadline || inst_chapter_module&.due_dates
      base_close = @student_extension.close_deadline || inst_chapter_module&.due_dates
      extension_params[:due_deadline] = base_due ? base_due + offset : nil
      extension_params[:close_deadline] = base_close ? base_close + offset : nil
    end

    if @student_extension.update(extension_params)
      render json: @student_extension
    else
      render json: { errors: @student_extension.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /egp_broker/student_extensions/:id
  def destroy
    @student_extension.destroy
    head :no_content
  end

  private

  def set_student_extension
    @student_extension = StudentExtension.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'StudentExtension not found' }, status: :not_found
  end

  def student_extension_params
    params.require(:student_extension).permit(:inst_chapter_module_id, :open_deadline, :time_limit)
  end
end 