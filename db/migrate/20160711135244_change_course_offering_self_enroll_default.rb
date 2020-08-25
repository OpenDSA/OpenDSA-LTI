class ChangeCourseOfferingSelfEnrollDefault < ActiveRecord::Migration[5.1]
  def change
      change_column_default(:course_offerings, :self_enrollment_allowed, true)
  end
end
