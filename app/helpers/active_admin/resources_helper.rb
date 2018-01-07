module ActiveAdmin
  module ResourcesHelper
    def confirmation_message(inst_book)
      book_title = inst_book.title
      last_compiled = inst_book.last_compiled
      course_offering = CourseOffering.where(:id => inst_book.course_offering_id)
      if !course_offering.empty?
        course_offering = course_offering.first
        course_offering_name = course_offering.display_name
        lms_course_num = course_offering.lms_course_num
        lms_url = LmsInstance.where(:id => course_offering.lms_instance_id).first.url
      end
      trailer = "Are you sure you want to proceed with the delete?"
      message1 = "You are about to delete '#{book_title}' book instance. "
      message2 = "The book is linked to '#{course_offering_name}' course offering. "
      message3 = "It was last compiled on '#{last_compiled}', and linked to '#{lms_url}' Instance, course number (#{lms_course_num}). If you delete this book the LMS course won't work and you will have to link a new book instance to the course offering and recompile it again. "

      message = message1 + trailer
      if !last_compiled and course_offering_name
        message = message1 + message2 + trailer
      elsif last_compiled and course_offering_name
        message = message1 + message2 + message3 + trailer
      end
      return message
    end

    def course_offering_delete_msg(co)
    end
  end
end