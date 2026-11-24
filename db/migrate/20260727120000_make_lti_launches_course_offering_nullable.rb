class MakeLtiLaunchesCourseOfferingNullable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :lti_launches, :course_offering_id, true
  end
end
