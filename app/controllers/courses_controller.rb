class CoursesController < ApplicationController
  load_and_authorize_resource
  skip_load_resource :only => :show
  skip_authorize_resource :only => :list
  respond_to :html, :js, :json

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # GET /courses
  def index
  end

  # -------------------------------------------------------------
  # GET /courses/1
  def show
    if params[:organization_id]
      @organization = Organization.find(params[:organization_id])
    end
    @course = Course.find_by(organization: @organization, slug: params[:id])
    if !@course
      flash[:warning] = 'Course not found.'
      redirect_to organizations_path
    elsif !params[:term_id]
      render 'show_terms'
    else
      @term = Term.find(params[:term_id])

      @course_offerings =
        current_user.andand.course_offerings_for_term(@term, @course)
      @is_student = !user_signed_in? ||
                    !current_user.global_role.is_admin? &&
                    (@course_offerings.any? { |co| co.is_student? current_user } ||
                     !@course_offerings.any? { |co| co.is_staff? current_user })
      # respond_to do |format|
      # format.js
      # format.html
      # end
    end
  end

  # -------------------------------------------------------------
  # GET /courses/1/list
  def list
    courses = Course.where(organization_id: params[:organization_id])
    render :json => courses.as_json, :status => :ok
  end

  # -------------------------------------------------------------
  # GET /courses/new
  def new
    @course = Course.new
  end

  # -------------------------------------------------------------
  # GET /courses/1/edit
  def edit
  end

  # -------------------------------------------------------------
  # POST /courses
  def create
    course_info = params[:course]
    course = Course.where(name: course_info[:name],
                          number: course_info[:number],
                          organization_id: course_info[:organization_id])
    unless course.blank?
      render json: ['A course with that number and name already exists for the selected organization.'], status: :forbidden
      return
    end
    course = Course.new(
      name: course_info[:name],
      number: course_info[:number],
      organization_id: course_info[:organization_id],
      user_id: current_user.id,
    )
    if course.save
      render :json => course.as_json, :status => :created
    else
      render :json => course.errors.full_messages, :status => :bad_request
      error = Error.new(:class_name => 'course_save_fail',
                        :message => course.errors.full_messages.inspect,
                        :params => params.to_s)
      error.save!
    end
  end

  # -------------------------------------------------------------
  # PATCH/PUT /courses/1
  def update
    if @course.update(course_params)
      redirect_to organization_courses_path(
                    @course.organization.id,
                    @course.id
                  ),
                  notice: "#{@course.display_name} was successfully updated."
    else
      render action: 'edit'
    end
  end

  # -------------------------------------------------------------
  # DELETE /courses/1
  def destroy
    description = @course.display_name
    if @course.destroy
      redirect_to organization_path(@course.organization),
        notice: "#{description} was successfully destroyed."
    else
      flash[:error] = "Unable to detroy #{description}."
      redirect_to organization_path(@course.organization)
    end
  end

  # -------------------------------------------------------------
  def search
    courses = Course.where("organization_id = ?", params['organization_id']).as_json

    respond_to do |format|
      format.json {
        render json: courses
      }
    end
  end

  # -------------------------------------------------------------
  def find
    @courses = Course.search(params[:search])
    redirect_to courses_search_path(courses: @courses, listing: true),
      format: :js, remote: true
  end

  # -------------------------------------------------------------
  # POST /courses/:id/generate_gradebook
  def generate_gradebook
    respond_to do |format|
      format.html
      format.csv do
        headers['Content-Disposition'] =
          "attachment; filename=\"#{@course.name} course gradebook.csv\""
        headers['Content-Type'] ||= 'text-csv'
      end
    end
  end

  #~ Private instance methods .................................................
  private

  # -------------------------------------------------------------
  # Only allow a trusted parameter "white list" through.
  def course_params
    params.require(:course).
      permit(:name, :id, :number, :organization_id, :term_id, :lms_course_code)
  end
end
