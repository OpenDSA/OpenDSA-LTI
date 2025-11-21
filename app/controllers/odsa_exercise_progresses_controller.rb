class OdsaExerciseProgressesController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................
  def update
    hasBook = params.key?(:inst_book_id)
    has_standalone_module = params.key?(:inst_module_section_exercise_id)
    if hasBook
      inst_book_section_exercise = nil
      if params.key?(:inst_book_section_exercise_id)
        inst_book_section_exercise = InstBookSectionExercise.find(params[:inst_book_section_exercise_id])
      else
        inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
        inst_book_section_exercise = InstBookSectionExercise.where(
          "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
          params[:inst_book_id], params[:inst_section_id], inst_exercise.id
        ).first
      end

      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                            current_user.id,
                                                            inst_book_section_exercise.id).first
        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                     inst_book_section_exercise: inst_book_section_exercise)
      end
    elsif has_standalone_module
      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_module_section_exercise_id=?",
                                                            current_user.id,
                                                            params[:inst_module_section_exercise_id]).first
        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                    inst_module_section_exercise_id: params[:inst_module_section_exercise_id])
      end
    else
      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_course_offering_exercise_id=?",
                                                            current_user.id,
                                                            params[:inst_course_offering_exercise_id]).first
        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                     inst_course_offering_exercise_id: params[:inst_course_offering_exercise_id])
      end
    end
    exercise_progress['current_exercise'] = params['current_exercise']

    respond_to do |format|
      if exercise_progress.save
        msg = {:status => "success", :message => "Success!"}
        format.json { render :json => msg }
      else
        msg = {:status => "fail", :message => exercise_progress.errors.full_messages}
        format.json { render :json => msg, :status => :bad_request }
        error = Error.new(:class_name => 'exercise_progress_save_fail',
                          :message => exercise_progress.errors.full_messages.inspect,
                          :params => params.to_s)
        error.save!
      end
    end
  end

  #/odsa_exercise_progresses?inst_chapter_module_id=&inst_book_id=
  def show_exercise
    if current_user.blank?
      @message = "Error: current user could not be identified"
      render :error
      return
    end

    if params.key?(:inst_chapter_module_id)
      show_section()
      return
    end
    hasBook = (params.key?(:inst_book_id) or params.key?(:inst_book_section_exercise_id))
    has_standalone_module = params.key?(:inst_module_section_exercise_id)
    if hasBook
      inst_book_section_exercise = nil
      if params.key?(:inst_book_section_exercise_id)
        inst_book_section_exercise = InstBookSectionExercise.find(params[:inst_book_section_exercise_id])
      else
        inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
        inst_book_section_exercise = InstBookSectionExercise.find_by(
          inst_book_id: params[:inst_book_id],
          inst_section_id: params[:inst_section_id],
          inst_exercise_id: inst_exercise.id,
        )
      end

      exercise_progress = OdsaExerciseProgress.find_by(
        inst_book_section_exercise_id: inst_book_section_exercise.id,
        user_id: current_user.id,
      )
      threshold = inst_book_section_exercise.threshold
    elsif has_standalone_module
      inst_module_section_exercise = InstModuleSectionExercise.find(params[:inst_module_section_exercise_id])
      exercise_progress = OdsaExerciseProgress.find_by(
        inst_module_section_exercise_id: inst_module_section_exercise.id,
        user_id: current_user.id,
      )
      threshold = inst_module_section_exercise.threshold
    else
      inst_course_offering_exercise = InstCourseOfferingExercise.find(params[:inst_course_offering_exercise_id])
      exercise_progress = OdsaExerciseProgress.find_by(
        inst_course_offering_exercise_id: inst_course_offering_exercise.id,
        user_id: current_user.id,
      )
      threshold = inst_course_offering_exercise.threshold
    end
    respond_to do |format|
      format.json {
        render :json => {
                 :exercise_progress => exercise_progress,
                 :threshold => threshold,
               }
      }
    end
  end

  # Retrieves proficiency status of all exercises
  def show_section
    book_progress = OdsaBookProgress.get_progress(current_user.id, params[:inst_book_id])
    proficient_exercises = nil
    if book_progress
      proficient_exercises = book_progress.get_proficient_exercises
    else
      proficient_exercises = []
    end

    respond_to do |format|
      format.json { render :json => {:proficient_exercises => proficient_exercises} }
    end
  end

  def get_count
    practiced_ex = OdsaExerciseProgress.where("proficient_date IS NOT NULL").count + OpenDSA::EXERCISES_SOLVED

    respond_to do |format|
      format.json { render :json => {:practiced_ex => practiced_ex} }
    end
  end

  def export_all_progress_csv
    if current_user.blank?
      render json: { message: 'You must be logged in to access this data.' }, status: :unauthorized
      return
    end

    course_offering = CourseOffering.find(params[:course_offering_id]) if params[:course_offering_id].present?

    unless current_user.global_role.is_admin? || (course_offering && course_offering.is_instructor?(current_user))
      render json: { message: "You are not authorized to view this data." },
            status: :forbidden and return
    end

    inst_book_id =
      if course_offering&.odsa_books&.first
        course_offering.odsa_books.first.id
      else
        nil
      end

    filename = "opendsa_progress_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    conn     = ActiveRecord::Base.connection

    sql = <<~SQL
      SELECT
        p.user_id,
        ie.name AS exercise,
        s.name AS section,
        p.current_score,
        p.highest_score,
        p.total_correct,
        p.first_done,
        p.last_done,
        p.proficient_date,

        -- attempts by this user on this ibse
        (
          SELECT COUNT(*)
          FROM odsa_exercise_attempts a
          WHERE a.user_id = p.user_id
            AND a.inst_book_section_exercise_id = p.inst_book_section_exercise_id
        ) AS total_attempts,

        -- points live on the book-section-exercise
        ibse.points AS points_possible,

        -- earn full points when proficient, else 0
        CASE
          WHEN p.proficient_date IS NOT NULL THEN ibse.points
          ELSE 0
        END AS points_earned

      FROM odsa_exercise_progresses p
        JOIN inst_book_section_exercises ibse ON ibse.id = p.inst_book_section_exercise_id
        JOIN inst_exercises ie               ON ie.id  = ibse.inst_exercise_id
        JOIN inst_sections s                 ON s.id   = ibse.inst_section_id
        JOIN inst_chapter_modules icm        ON icm.id = s.inst_chapter_module_id
        JOIN inst_chapters ich               ON ich.id = icm.inst_chapter_id
        JOIN users u                         ON u.id   = p.user_id
      WHERE u.email != #{conn.quote(OpenDSA::STUDENT_VIEW_EMAIL)}
        #{inst_book_id ? "AND ich.inst_book_id = #{conn.quote(inst_book_id)}" : ""}
        -- only include rows where the student actually attempted the exercise
        AND EXISTS (
          SELECT 1
          FROM odsa_exercise_attempts a
          WHERE a.user_id = p.user_id
            AND a.inst_book_section_exercise_id = p.inst_book_section_exercise_id
        )
      ORDER BY p.user_id, ie.short_name
    SQL

    rows = conn.exec_query(sql)

    header = %w[
      user_id
      exercise
      section
      current_score
      highest_score
      total_correct
      first_done
      last_done
      proficient_date
      total_attempts
      points_earned
      points_possible
    ]

    csv_data = CSV.generate(headers: true) do |csv|
      csv << header
      rows.each { |r| csv << header.map { |k| r[k] } }
    end

    send_data csv_data,
              filename: filename,
              type: "text/csv; charset=utf-8"
  end

  #~ Private instance methods .................................................
end
