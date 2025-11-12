class CourseOfferingsController < ApplicationController
  before_action :rename_course_offering_id_param
  # before_action :authorize_user_for_course_offering_data, only: [:show, :get_individual_attempt, :find_attempts]
  before_action :authorize_user_for_course_offering_data, 
              only: [:show, :get_individual_attempt, :find_attempts, :get_codeworkout_progress, :find_module_progresses]
  # load_and_authorize_resource

  # -------------------------------------------------------------
  # GET /course_offerings
  def index
  end

  # -------------------------------------------------------------
  # GET /course_offerings/1
  def show
    @course_offering = CourseOffering.find_by(id: params[:id])
    @url = url_for(organization_course_path(
      @course_offering.course.organization,
      @course_offering.course,
      @course_offering.term
    ))

    @course_enrollment = CourseEnrollment.where("course_offering_id=?", @course_offering.id)
    @student_list = []
    #puts @course_enrollment.inspect
    @course_enrollment.each do |s|
      q = User.where("id=?", s.user_id).select("id, first_name, last_name")
      @student_list.push(q)
    end
    @instBook = @course_offering.odsa_books.first

    @exercise_list = Hash.new
    chapters = InstChapter.where(inst_book_id: @instBook.id).order('position')
    chapters.each do |chapter|
      modules = InstChapterModule.where(inst_chapter_id: chapter.id).order('module_position')
      modules.each do |inst_ch_module|
        sections = InstSection.where(inst_chapter_module_id: inst_ch_module.id)
        section_item_position = 1
        if !sections.empty?
          sections.each do |section|
            title = (chapter.position.to_s.rjust(2, "0") || "") + "." +
                    (inst_ch_module.module_position.to_s.rjust(2, "0") || "") + "." +
                    section_item_position.to_s.rjust(2, "0") + " - "
            learning_tool = nil
            if section
              title = title + section.name
              learning_tool = section.learning_tool
              if !learning_tool
                if section.gradable
                  @exercise_list[section.id] = title
                end
              end
            end
            section_item_position += 1
          end
        end
      end
    end
  end

  # GET /course_offerings/indAssigment/assignmentList/student/exercise'
  def ind_assigment
    puts "show assignement"
    render(:partial => 'lti/show_individual_exercise.html.haml') and return
  end

# GET /course_offerings/:user_id/id/exercise_list
def get_individual_attempt
  if params[:user_id].present?
    @user_id = User.find_by(id: params[:user_id])
  else
    @user_id = current_user
  end
  @course_offering = CourseOffering.find_by(id: params[:id])
  @url = url_for(organization_course_path(
    @course_offering.course.organization,
    @course_offering.course,
    @course_offering.term
  ))

  @course_enrollment = CourseEnrollment.where("course_offering_id=?", @course_offering.id)
  @student_list = []
  #puts @course_enrollment.inspect
  @course_enrollment.each do |s|
    q = User.where("id=?", s.user_id).select("id, first_name, last_name")
    @student_list.push(q)
  end
  @instBook = @course_offering.odsa_books.first

  @exercise_list = Hash.new { |hsh, key| hsh[key] = [] }
  chapters = InstChapter.where(inst_book_id: @instBook.id).order('position')
  chapters.each do |chapter|
    modules = InstChapterModule.where(inst_chapter_id: chapter.id).order('module_position')
    modules.each do |inst_ch_module|
      sections = InstSection.where(inst_chapter_module_id: inst_ch_module.id)
      section_item_position = 1
      if !sections.empty?
        sections.each do |section|
          title = (chapter.position.to_s.rjust(2, "0") || "") + "." +
                  (inst_ch_module.module_position.to_s.rjust(2, "0") || "") + "." +
                  section_item_position.to_s.rjust(2, "0") + " - "
          learning_tool = nil
          if section
            title = title + section.name
            learning_tool = section.learning_tool
            if !learning_tool
              if section.gradable
                @inst_section_id = section.id
                
                # Check if we should use proficiency-based completion
                check_proficiency = params[:check_proficiency] == 'true'
                
                if check_proficiency
                  # Check for proficiency
                  inst_book_section_exercise = InstBookSectionExercise.where(
                    inst_section_id: @inst_section_id,
                    required: true
                  ).first
                  
                  @exercise_list[@inst_section_id].push(title)
                  
                  if inst_book_section_exercise
                    progress = OdsaExerciseProgress.where(
                      "inst_book_section_exercise_id=? AND user_id=?",
                      inst_book_section_exercise.id,
                      @user_id
                    ).first
                    
                    if progress && progress.proficient_date.present?
                      @exercise_list[@inst_section_id].push('complete_flag')
                    end
                  end
                else
                  # But also Check for any attempts (unchanged behavior)
                  attempted = OdsaExerciseAttempt.where("inst_section_id=? AND user_id=?",
                                                        @inst_section_id, @user_id)
                  if attempted.empty?
                    @exercise_list[@inst_section_id].push(title)
                  else
                    @exercise_list[@inst_section_id].push(title)
                    @exercise_list[@inst_section_id].push('attempt_flag')
                  end
                end
              end
            end
          end
          section_item_position += 1
        end
      end
    end
  end
end

  # GET /course_offerings/:user_id/:inst_section_id/section
  def find_attempts
    if params[:user_id].present?
      @user_id = User.find_by(id: params[:user_id])
    else
      @user_id = current_user
    end
    @inst_section = InstSection.find_by(id: params[:inst_section_id])
    @inst_book_section_exercise = InstBookSectionExercise.where(inst_section_id: @inst_section.id, required: true).first #not sure about the first
    @inst_book_section_exercise_id = @inst_book_section_exercise.id

    @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_book_section_exercise_id=? AND user_id=?",
                                                        @inst_book_section_exercise_id, @user_id).select(
      "id, user_id, question_name, request_type,
                                 correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                 pe_score, pe_steps_fixed"
    )
    @odsa_exercise_progress = OdsaExerciseProgress.where("inst_book_section_exercise_id=? AND user_id=?",
                                                         @inst_book_section_exercise_id, @user_id).select("user_id, current_score, highest_score,
                                 total_correct, proficient_date,first_done, last_done")

    @attempts_json = ApplicationController.new.render_to_string(
      template: 'course_offerings/find_attempts.json.jbuilder',
      locals: {:@odsa_exercise_attempts => @odsa_exercise_attempts,
               :@odsa_exercise_progress => @odsa_exercise_progress,
               :@inst_book_section_exercise => @inst_book_section_exercise,
               :@inst_section => @inst_section},
    )
  end

  # GET /course_offerings/:id/codeworkout_progress
def get_codeworkout_progress
  if params[:user_id].present?
    @user_id = User.find_by(id: params[:user_id])
  else
    @user_id = current_user
  end
  
  @inst_book_section_exercise_id = params[:inst_book_section_exercise_id]
  
  if @inst_book_section_exercise_id.blank?
    render json: { error: 'inst_book_section_exercise_id is required' }, status: :bad_request
    return
  end
  
  @progress = OdsaExerciseProgress.where(
    "inst_book_section_exercise_id = ? AND user_id = ?",
    @inst_book_section_exercise_id,
    @user_id
  ).select("current_score, highest_score, total_correct, proficient_date, first_done, last_done").first
  
  if @progress
    render json: @progress
  else
    render json: { completed: false }
  end
end

  # GET /course_offerings/:id/modules/:inst_chapter_module_id/progresses
  def find_module_progresses
    if current_user.blank?
      render :json => {
        message: 'You are not logged in. Please make sure your browser is set to allow third-party cookies',
      }, :status => :forbidden
      return
    end

    chapt_mod = InstChapterModule.find(params[:inst_chapter_module_id])
    course_offering = chapt_mod.inst_chapter.inst_book.course_offering
    unless course_offering.is_instructor?(current_user) || current_user.global_role.is_admin?
      render :json => {
        message: 'You are not an instructor for this course offering. Your user id: ' + current_user.id.to_s,
      }, :status => :forbidden
      return
    end

    exercises = InstBookSectionExercise.includes(:inst_exercise, inst_section: [:inst_chapter_module]).where("inst_chapter_modules.id = ? AND inst_book_section_exercises.points > 0", params[:inst_chapter_module_id]).references(:inst_chapter_modules)

    ex_ids = exercises.collect { |ex| ex.id }

    users = CourseEnrollment.where(course_offering_id: course_offering.id).where('users.email != ?', OpenDSA::STUDENT_VIEW_EMAIL).joins(:user).includes(:user).order('users.id ASC').collect { |e| e.user }

    # only includes students who have attempted at least one exercise in the module
    # but also includes exercise attempt and progress data
    enrollments = CourseEnrollment.joins(:user).includes(user: [:odsa_module_progresses, :odsa_exercise_progresses]).where("course_enrollments.course_offering_id = ? AND course_enrollments.course_role_id = ? AND odsa_module_progresses.inst_chapter_module_id = ? AND odsa_exercise_progresses.inst_book_section_exercise_id IN (?)", params[:id], CourseRole::STUDENT_ID, params[:inst_chapter_module_id], ex_ids).references(:course_enrollments, :odsa_module_progresses, :odsa_exercise_progresses)

    render :json => {
      exercises: exercises.as_json(include: :inst_exercise),
      enrollments: enrollments.as_json(include: {user: {include: {odsa_module_progresses: {only: [:current_score, :first_done, :last_done, :highest_score, :id, :proficient_date, :created_at]}, odsa_exercise_progresses: {only: [:id, :inst_book_section_exercise_id, :current_score, :highest_score, :proficient_date]}}, only: [:id, :first_name, :last_name, :email, :odsa_module_progresses]}}),
      students: users.as_json(only: [:id, :first_name, :last_name, :email]),
    }
  end

  # GET /course_offerings/time_tracking_lookup/:id
  def get_time_tracking_lookup
    if current_user.blank?
      render :json => {
        message: 'You are not logged in. Please make sure your browser is set to allow third-party cookies',
      }, :status => :forbidden
      return
    end

    course_offering = CourseOffering.find(params[:id])
    unless course_offering.is_instructor?(current_user) || current_user.global_role.is_admin?
      render :json => {
        message: 'You are not an instructor for this course offering. Your user id: ' + current_user.id.to_s,
      }, :status => :forbidden
      return
    end

    users = CourseEnrollment.where(course_offering_id: course_offering.id).joins(:user).includes(:user).order('users.id ASC').collect { |e| e.user }

    instBook = course_offering.odsa_books.first
    chapters = InstChapterModule.joins("INNER JOIN inst_chapters ON inst_chapters.id = inst_chapter_modules.inst_chapter_id
                                        INNER JOIN inst_modules ON inst_modules.id = inst_chapter_modules.inst_module_id")
                                        .where("inst_chapters.inst_book_id=?", instBook.id)
                                        .select('inst_chapters.id as ch_id,inst_chapters.name as ch_name,inst_chapter_modules.inst_module_id as mod_id, inst_modules.name as mod_name, inst_chapter_modules.lms_assignment_id as assign_id, inst_chapter_modules.id as ch_mod_id')
                                        .order('inst_chapters.position')

    term = Term.where(id: course_offering.term_id)

    render :json => {
      users: users.as_json(only: [:id, :first_name, :last_name, :email]),
      chapters: chapters.as_json(),
      term: term.as_json(only: [:starts_on, :ends_on, :year, :slug])
    }
  end

  # GET /course_offerings/time_tracking_data/:id
  def get_time_tracking_data
    if current_user.blank?
      render :json => {
        message: 'You are not logged in. Please make sure your browser is set to allow third-party cookies',
      }, :status => :forbidden
      return
    end

    course_offering = CourseOffering.find(params[:id])
    unless course_offering.is_instructor?(current_user) || current_user.global_role.is_admin?
      render :json => {
        message: 'You are not an instructor for this course offering. Your user id: ' + current_user.id.to_s,
      }, :status => :forbidden
      return
    end

    instBook = course_offering.odsa_books.first

    userTimeTrackings = OdsaUserTimeTracking.where(inst_book_id: instBook.id, session_date: params[:date]).select('user_id as usr_id,inst_module_id as mod_id, inst_chapter_id as ch_id, total_time as tt, session_date as dt, sections_time as st')

    render :json => userTimeTrackings.as_json()
  end

  # -------------------------------------------------------------
  # GET /course_offerings/new
  def new
  end

  # -------------------------------------------------------------
  # GET /course_offerings/1/edit
  def edit
    @uploaded_roster = UploadedRoster.new
  end

  # -------------------------------------------------------------
  # POST /course_offerings
  def create
    unless params.key?(:inst_book_id)
      create_lti_course_offering
      return
    end
    lms_instance = LmsInstance.find_by(id: params[:lms_instance_id])
    course = Course.find_by(id: params[:course_id])
    term = Term.find_by(id: params[:term_id])
    # late_policy = LatePolicy.find_by(id: params[:late_policy_id])
    inst_book = InstBook.find_by(id: params[:inst_book_id])

    course_offering = CourseOffering.where(
      "course_id=? and term_id=? and label=? and lms_instance_id=?",
      params[:course_id], params[:term_id], params[:label], params[:lms_instance_id]
    ).first

    if course_offering.blank?
      course_offering = CourseOffering.new(
        course: course,
        term: term,
        label: params[:label],
        # late_policy: late_policy || nil,
        lms_instance: lms_instance,
        lms_course_code: params[:lms_course_code],
        lms_course_num: params[:lms_course_num],
      )

      cloned_book = inst_book.clone(current_user)

      if course_offering.save!
        # Add course_offering to the new book
        cloned_book.course_offering_id = course_offering.id
        cloned_book.save!

        if !params['lms_access_token'].blank?
          lms_access = LmsAccess.where("user_id = ?", current_user.id).first
          if !lms_access
            lms_access = LmsAccess.new(
              lms_instance: lms_instance,
              user: current_user,
              access_token: params[:lms_access_token],
            )
            lms_access.save!
          end
          lms_access.access_token = params[:lms_access_token]
          lms_access.save!
        end

        # Enroll user as course_offering instructor
        enrollment = CourseEnrollment.new
        enrollment.course_offering_id = course_offering.id
        enrollment.user_id = current_user.id
        enrollment.course_role_id = CourseRole.instructor.id
        enrollment.save!
      else
        err_string = 'There was a problem while creating the course offering.'
        url = url_for new_course_offerings_path(notice: err_string)

      end
    end

    if !url
      url = url_for(organization_course_path(
        course_offering.course.organization,
        course_offering.course,
        course_offering.term
      ))
    end

    respond_to do |format|
      format.json { render json: {url: url} }
    end
  end

  # -------------------------------------------------------------
  # POST /course_enrollments
  # Public: Creates a new course enrollment based on enroll link.
  # FIXME:  Not really sure this is the best place to do it.

  # def enroll
  #   if @course_offering &&
  #     @course_offering.can_enroll? &&
  #     CourseEnrollment.create(
  #     course_offering: @course_offering,
  #     user: current_user,
  #     course_role: CourseRole.student)

  #     redirect_to organization_course_path(
  #       @course_offering.course.organization,
  #       @course_offering.course,
  #       @course_offering.term),
  #       notice: 'You are now enrolled in ' +
  #         "#{@course_offering.display_name}."
  #   else
  #     flash[:warning] = 'Unable to enroll in that course.'
  #     redirect_to root_path
  #   end
  # end

  # -------------------------------------------------------------
  # DELETE /unenroll
  # Public: Deletes an enrollment, if it exists.
  # def unenroll
  #   if @course_offering
  #     path = organization_course_path(
  #       @course_offering.course.organization,
  #        @course_offering.course,
  #       @course_offering.term)
  #     description = @course_offering.display_name

  #     @course_offering.course_enrollments.where(user: current_user).destroy_all
  #     redirect_to path, notice: "You have unenrolled from #{description}."
  #   else
  #     flash[:error] =
  #       'No course offering was specified in your unenroll request.'
  #     redirect_to root_path
  #   end
  # end

  # -------------------------------------------------------------
  # GET /course_offerings/:id/upload_roster
  # Method to enroll students from an uploaded roster.
  # TODO: Needs to be redone so that it will read an actual CSV
  #       file of student enrollment info and not just a list of
  #       e-mail addresses.
  def upload_roster
    form_contents = params[:form]
    puts form_contents.fetch(:rosterfile).path
    CSV.foreach(form_contents.fetch(:rosterfile).path) do |enroller|
      student = User.find_by!(email: enroller)
      co = CourseEnrollment.new(user: student, course_offering_id: params[:id], course_role_id: 3)
      co.save!
    end
    redirect_to root_path
  end

  # -------------------------------------------------------------
  # PATCH/PUT /course_offerings/1
  def update
    if @course_offering.update(course_offering_params)
      redirect_to organization_course_path(
                    @course_offering.course.organization,
                    @course_offering.course,
                    @course_offering.term
                  ),
                  notice: "#{@course_offering.display_name} was successfully updated."
    else
      render action: 'edit'
    end
  end

  # -------------------------------------------------------------
  # DELETE /course_offerings/1
  def destroy
    description = @course_offering.display_name
    path = organization_course_path(
      @course_offering.course.organization,
      @course_offering.course,
      @course_offering.term
    )
    if @course_offering.destroy
      redirect_to path,
        notice: "#{description} was successfully destroyed."
    else
      flash[:error] = "Unable to destroy #{description}."
      redirect_to path
    end
  end

  # -------------------------------------------------------------
  def generate_gradebook
    @course_enrolled = CourseEnrollment.where(course_offering: @course_offering).
      sort_by { |ce| [ce.user.last_name.to_s.downcase, ce.user.first_name.to_s.downcase, ce.user.email] }
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] =
          "attachment; filename=\"#{@course_offering.course.number}-" \
          "#{@course_offering.label}-Gradebook.csv\""
        headers['Content-Type'] ||= 'text-csv'
      end
    end
  end

  # -------------------------------------------------------------
  # GET /course_offerings/:id/add_workout
  def add_workout
    @workouts = Workout.all
    @wkts = []
    @course_offering.workouts.each do |wks|
      @wkts << wks
    end
    @workouts = @workouts - @wkts
    @course_offering
  end

  # -------------------------------------------------------------
  # POST /course_offerings/store_workout/:id
  def store_workout
    workouts = params[:workoutids]
    workouts.each do |wkid|
      wk = Workout.find(wkid)
      @course_offering.workouts << wk
      @course_offering.save
      wek = @course_offering.workout_offerings.where(workout_id: wkid)
      wek.last.opening_date = params[:opening_date]
      wek.last.soft_deadline = params[:soft_deadline]
      wek.last.hard_deadline = params[:hard_deadline]
      wek.last.save
    end
    redirect_to course_offering_path(@course_offering),
      notice: 'Workouts added to course offering!'
  end

  #~ Private instance methods .................................................
  private

  def create_lti_course_offering
    # if not can? :create, CourseOffering
    #   render :json => ['You are not authorized to create course offerings.'], :status => :forbidden
    #   return
    # end
    info = params[:course_offering]
    course_offering = CourseOffering.new(
      course_id: info[:course_id],
      term_id: info[:term_id],
      label: info[:label],
      lms_instance_id: info[:lms_instance_id],
      lms_course_code: info[:lms_course_code],
      lms_course_num: info[:lms_course_num],
    )
    if course_offering.save
      CourseEnrollment.create(
        course_offering: course_offering,
        user: current_user,
        course_role: CourseRole.instructor,
      )
      render :json => course_offering.as_json, :status => :created
    else
      render :json => course_offering.errors.full_messages, :status => :bad_request
      error = Error.new(:class_name => 'course_offering_save_fail',
                        :message => course_offering.errors.full_messages.inspect,
                        :params => params.to_s)
      error.save!
    end
  end

  # -------------------------------------------------------------
  def rename_course_offering_id_param
    if params[:course_offering_id] && !params[:id]
      params[:id] = params[:course_offering_id]
    end
  end

  # -------------------------------------------------------------
  # Only allow a trusted parameter "white list" through.
  def course_offering_params
    params.require(:course_offering).permit(:course_id, :term_id,
                                            :label, :url, :self_enrollment_allowed)
  end

  def authorize_user_for_course_offering_data
    if current_user.blank?
      render json: { message: 'You must be logged in to access this data.' }, status: :unauthorized
      return
    end

    course_offering = nil
    if params[:id].present?
      course_offering = CourseOffering.find_by(id: params[:id])
    elsif params[:course_offering_id].present?
      course_offering = CourseOffering.find_by(id: params[:course_offering_id])
    elsif params[:inst_section_id].present?
      inst_section = InstSection.find_by(id: params[:inst_section_id])
      if inst_section.present? && inst_section.inst_chapter_module.present? && inst_section.inst_chapter_module.inst_chapter.present? && inst_section.inst_chapter_module.inst_chapter.inst_book.present?
        course_offering = inst_section.inst_chapter_module.inst_chapter.inst_book.course_offering
      end
    end

    if course_offering.blank?
      render json: { message: 'Course offering not found.' }, status: :not_found
      return
    end

    # Allow access if the user is an instructor for the course or an admin
    if current_user.global_role.is_admin? || course_offering.is_instructor?(current_user)
      return
    end

    # Allow access if the user is requesting their own data
    if params[:user_id].present? && current_user.id.to_s == params[:user_id]
      return
    end

    # In the 'show' action, a student should be able to see the course offering if they are enrolled.
    if (action_name == 'show' || 
        action_name == 'get_individual_attempt' || 
        action_name == 'find_attempts' ||
        action_name == 'get_codeworkout_progress' ||
        action_name == 'find_module_progresses') && 
      course_offering.is_enrolled?(current_user)
      return
    end

    render json: { message: 'You are not authorized to access this data.' }, status: :forbidden
  end

end
