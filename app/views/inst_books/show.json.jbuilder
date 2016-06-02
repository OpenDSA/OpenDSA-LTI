json.(@inst_book, :title, :book_url, :book_code)

json.chapters do
  json.array!(@inst_book.inst_chapters) do |inst_chapter|
    json.id inst_chapter.id
    json.name inst_chapter.name

    json.modules do
      json.array!(inst_chapter.inst_chapter_modules) do |inst_chapter_module|
        json.id inst_chapter_module.id
        json.path InstModule.where(:id => inst_chapter_module.inst_module_id).first.path
        json.name InstModule.where(:id => inst_chapter_module.inst_module_id).first.name

        json.sections do
          json.array!(inst_chapter_module.inst_sections) do |inst_section|
            json.id inst_section.id
            json.name inst_section.name
            json.show inst_section.show

            json.exercises do
              json.array!(inst_section.inst_book_section_exercises) do |inst_book_section_exercise|
                json.id inst_book_section_exercise.id
                json.name inst_section.name
                json.name InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.name
                json.short_name InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.short_name
                json.required inst_book_section_exercise.required
                json.threshold inst_book_section_exercise.threshold
              end
            end

          end
        end

      end
    end

  end
end
