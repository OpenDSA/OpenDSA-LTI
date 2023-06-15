json.set! :inst_book_id, @inst_book.id
json.set! :title, @inst_book.title
json.set! :desc, @inst_book.desc
json.set! :last_compiled, @inst_book.last_compiled.try(:strftime, "%Y-%m-%d %H:%m:%S")

options = @inst_book.options
if options != nil && options != "null"
  options = eval(options)
  options.each do |key, value|
    json.set! key, value
  end
end

# chapters
json.chapters do
  for inst_chapter in @inst_book.inst_chapters.order('position')
    chapter_name = inst_chapter.name
    # chapter object
    json.set! chapter_name do
      json.set! :lms_chapter_id, inst_chapter.lms_chapter_id
      json.set! :lms_assignment_group_id, inst_chapter.lms_assignment_group_id
      
      for inst_chapter_module in inst_chapter.inst_chapter_modules.order('module_position')
        module_path = InstModule.where(:id => inst_chapter_module.inst_module_id).first.path
        
        # module Object
        json.set! module_path do
          json.set! :lms_module_item_id, inst_chapter_module.lms_module_item_id
          json.set! :lms_section_item_id, inst_chapter_module.lms_section_item_id
          json.set! :lms_assignment_id, inst_chapter_module.lms_assignment_id
          json.set! :long_name, InstModule.where(:id => inst_chapter_module.inst_module_id).first.name
          json.set! :due_dates, inst_chapter_module.due_dates.try(:strftime, "%m/%d/%Y %I:%M %P")

          # sections
          json.sections do
            sections = inst_chapter_module.inst_sections
            if !sections.empty?
              for inst_section in inst_chapter_module.inst_sections
                section_name = inst_section.name

                # section object
                json.set! section_name do
                  json.set! :id, inst_section.id
                  json.set! :soft_deadline, inst_section.soft_deadline.try(:strftime, "%Y-%m-%d %H:%m:%S")
                  json.set! :hard_deadline, inst_section.soft_deadline.try(:strftime, "%Y-%m-%d %H:%m:%S")
                  json.set! :showsection, inst_section.show
                  json.set! :lms_item_id, inst_section.lms_item_id
                  json.set! :lms_assignment_id, inst_section.lms_assignment_id

                  learning_tool = inst_section.learning_tool
                  if learning_tool
                    exercise = inst_section.inst_book_section_exercises.first
                    if exercise
                      if !exercise.json.blank?
                        json.merge! JSON.parse(exercise.json)
                      end
                      json.set! :points, exercise.points.to_f
                      json.set! :launch_url, "#{@extrtool_launch_base_url}/#{exercise.id}"
                    end
                    json.set! :learning_tool, learning_tool
                    json.set! :resource_type, inst_section.resource_type
                    json.set! :resource_name, inst_section.resource_name
                  else
                    exercises = inst_section.inst_book_section_exercises
                    if !exercises.empty?
                      exercises.each do |inst_book_section_exercise|
                        exercise_name = InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.short_name
                        json.set! exercise_name do
                          if !inst_book_section_exercise.json.blank?
                            json.merge! JSON.parse(inst_book_section_exercise.json)
                          end
                          json.set! :id, inst_book_section_exercise.id
                          json.set! :long_name, InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.name
                          json.set! :required, inst_book_section_exercise.required
                          json.set! :points, inst_book_section_exercise.points.to_f
                          json.set! :threshold, inst_book_section_exercise.threshold.to_f
                          options = inst_book_section_exercise.options
                          if !options.blank? && options != "null"
                            # FIXME: shouldn't eval() here be JSON.parse()?
                            json.set! :exer_options, JSON.parse(options)
                          end
                        end
                      end
                    end
                  end
                end
              end
            else
              json.nil!
            end
          end
        end
      end
    end
  end
end
course_offering = CourseOffering.where(:id => @inst_book.course_offering_id).first

if course_offering != nil
  json.course_id course_offering.lms_course_num
  lms_instance_id = course_offering.lms_instance_id
  json.LMS_url LmsInstance.where(:id => lms_instance_id).first.url
end
