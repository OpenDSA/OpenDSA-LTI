class ExportController < ApplicationController
  # GET /export
  def index

    host_url = request.base_url
    @exercises = InstExercise.joins(inst_book_section_exercises: { inst_section: { inst_chapter_module: :inst_chapter } })
                             .select("inst_exercises.*, inst_chapters.name AS chapter_name")

    export_data = @exercises.map do |exercise|
      {
        "catalog_type": "SLCItemCatalog",
        "platform_name": "OpenDSA",
        "url": exercise.embed_url(host_url),
        "lti_instructions_url": "https://opendsa-server.cs.vt.edu/guides/lti-instructions",
        "exercise_type": exercise.ex_type,
        "license": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)",
        "description": exercise.description,
        "author": "Cliff Shaffer",
        "institution": "Virginia Tech",
        "keywords": exercise.chapter_name,
        "exercise_Name": exercise.name,
        "iframe_URL": exercise.embed_url(host_url),
        "lti_url": "#{host_url}/lti/launch?custom_ex_short_name=#{exercise.short_name}"
      }
    end

    render json: export_data
  end
end


  
