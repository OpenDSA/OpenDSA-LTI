class TextbooksController < ApplicationController

  def new

  end
  def create
    # Textbooks are CourseOffering with no LMS interaction
    # Hence the LMS instance TEXTBOOK is used for all CourseOfferings
    # that are TEXTBOOKS
    lms_instance = LmsInstance.find_by(url: "TEXTBOOK")
    course = Course.find_by(id: params[:course_id])
    term = Term.find_by(id: params[:term_id])
    inst_book = InstBook.find_by(id: params[:inst_book_id])

    course_offering = CourseOffering.where(
      "course_id=? and term_id=? and label=? and lms_instance_id=?",
      params[:course_id], params[:term_id], params[:label], lms_instance.id
    ).first

    if course_offering.blank?
      course_offering = CourseOffering.new(
        course: course,
        term: term,
        label: params[:label],
        lms_instance: lms_instance,
        lms_course_num: 9999999
        )

      cloned_book = inst_book.clone(current_user)

      if course_offering.save!
        cloned_book.course_offering_id = course_offering.id
        cloned_book.save!

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

end
