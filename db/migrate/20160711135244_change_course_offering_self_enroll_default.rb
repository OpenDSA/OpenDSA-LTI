class ChangeCourseOfferingSelfEnrollDefault < ActiveRecord::Migration
  def change
      change_column_default(:course_offerings, :self_enrollment_allowed, true)
  end
end
