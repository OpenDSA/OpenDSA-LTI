class ExportController < ApplicationController
  # GET /export
  def index

    host_url = request.base_url
    @exercises = InstExercise.joins(inst_book_section_exercises: { inst_section: { inst_chapter_module: :inst_chapter } })
                             .select("inst_exercises.*, inst_chapters.name AS chapter_name")

    export_data = @exercises.map do |exercise|
      {
        "Platform_name": "OpenDSA",
        "URL": exercise.embed_url(host_url),
        "LTI_Instructions_URL": "https://opendsa-server.cs.vt.edu/guides/lti-instructions",
        "Exercise_type": exercise.ex_type,
        "License": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)",
        "Description": exercise.description,
        "Author": "Shaffer",
        "Institution": "Virginia Tech",
        "Keywords": exercise.chapter_name,
        "Exercise_Name": exercise.name,
        "Iframe_URL": exercise.embed_url(host_url),
        "LTI_URL": "#{host_url}/lti/launch?custom_ex_short_name=#{exercise.short_name}"
        
      }
    end

    render json: export_data
  end
end


  