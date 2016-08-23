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
          json.set! :long_name, InstModule.where(:id => inst_chapter_module.inst_module_id).first.name

          # sections
          json.sections do
            sections = inst_chapter_module.inst_sections
            if !sections.empty?

              for inst_section in inst_chapter_module.inst_sections
                section_name = inst_section.name

               # section object
                json.set! section_name do
                  if !inst_section.show
                    json.set! :show, inst_section.show
                  end
                  json.set! :lms_item_id, inst_section.lms_item_id
                  json.set! :lms_assignment_id, inst_section.lms_assignment_id
                  learning_tool = inst_section.learning_tool
                  if learning_tool
                    json.set! :learning_tool, learning_tool
                    json.set! :resource_type, inst_section.resource_type
                    json.set! :resource_name, inst_section.resource_name
                    exercise = inst_section.inst_book_section_exercises.first
                    json.set! :points, exercise.points.to_f
                  else
                    exercises = inst_section.inst_book_section_exercises
                    if !exercises.empty?
                      for inst_book_section_exercise in exercises
                        exercise_name = InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.short_name
                        json.set! exercise_name do
                          json.set! :long_name, InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.name
                          json.set! :required, inst_book_section_exercise.required
                          json.set! :points, inst_book_section_exercise.points.to_f
                          json.set! :threshold, inst_book_section_exercise.threshold.to_f
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
json.course_id CourseOffering.where(:id => @inst_book.course_offering_id).first.lms_course_num
lms_instance_id = CourseOffering.where(:id => @inst_book.course_offering_id).first.lms_instance_id
json.LMS_url LmsInstance.where(:id => lms_instance_id).first.url