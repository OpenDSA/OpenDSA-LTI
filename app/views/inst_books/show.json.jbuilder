json.(@inst_book, :title, :book_url, :book_code)

# chapters
json.chapters do

  for inst_chapter in @inst_book.inst_chapters

    chapter_name = inst_chapter.name
    # chapter object
    json.set! chapter_name do

      for inst_chapter_module in inst_chapter.inst_chapter_modules
        module_path = InstModule.where(:id => inst_chapter_module.inst_module_id).first.path

        # module Object
        json.set! module_path do
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
                  else
                    json.empty :empty
                  end
                end
              end
            else
              json.empty :empty
            end
          end
        end

      end
    end

  end

end