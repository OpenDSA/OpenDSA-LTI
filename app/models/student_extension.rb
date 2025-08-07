class StudentExtension < ApplicationRecord
  belongs_to :user
  belongs_to :inst_chapter_module

  def self.create_or_update!(student, inst_chapter_module, opts)
    ext = find_or_initialize_by(user: student, inst_chapter_module: inst_chapter_module)
    ext.open_deadline  = opts[:open_deadline]  if opts[:open_deadline]
    ext.due_deadline   = opts[:due_deadline]   if opts[:due_deadline]
    ext.close_deadline = opts[:close_deadline] if opts[:close_deadline]
    ext.time_limit     = opts[:time_limit]     if opts[:time_limit]
    ext.save!
  end
end 