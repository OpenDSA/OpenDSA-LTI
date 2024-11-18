# == Schema Information
#
# Table name: student_extensions
#
#  id                     :bigint           not null, primary key
#  user_id                :integer
#  inst_chapter_module_id :integer
#  open_date              :datetime
#  close_date             :datetime
#  due_date               :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_student_extensions_on_inst_chapter_module_id  (inst_chapter_module_id)
#  index_student_extensions_on_user_id                 (user_id)
#
class StudentExtension < ApplicationRecord
  
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_chapter_module

  # Creates new or updates an existing StudentExtension.
  def self.create_or_update!(student, inst_chapter_module, opts)
    student_extension = StudentExtension.find_by(user: student, inst_chapter_module: inst_chapter_module)

    if student_extension.blank?
      student_extension = StudentExtension.new
    end

    student_extension.user = student
    student_extension.inst_chapter_module = inst_chapter_module

    if opts['open_date'].present?
      student_extension.open_date =
        DateTime.strptime(opts['open_date'].to_s, '%Q')
    end
    if opts['due_date'].present?
      student_extension.due_date =
        DateTime.strptime(opts['due_date'].to_s, '%Q')
    end
    if opts['close_date'].present?
      student_extension.close_date =
        DateTime.strptime(opts['close_date'].to_s, '%Q')
    end

    student_extension.time_limit = opts['time_limit'] if opts['time_limit'].present?
    student_extension.save!

  end

end
