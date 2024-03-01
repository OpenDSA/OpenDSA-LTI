class ExportController < ApplicationController
  # GET /export
  # gives an export of opendsa embeddable slideshows and exercises
  # with iframe and lti urls for SPLICE catalog
  def index
    host_url = request.base_url
    inst_book = InstBook.first
    raise "InstBook instance not found" unless inst_book

    av_data = inst_book.extract_av_data_from_rst
    @exercises = InstExercise.all

    export_data = @exercises.map do |exercise|
      matching_chapter = nil
      matching_avmetadata = nil

      av_data.each do |chapter, data|
        if data[:inlineav]&.include?(exercise.short_name) || data[:avembed]&.include?(exercise.short_name)
          matching_avmetadata = data[:avmetadata]
          matching_chapter = chapter
          break
        end
      end

      # Handle keywords split by either commas or semicolons, return as comma-separated
      keywords = if matching_avmetadata && (matching_avmetadata[:satisfies] || matching_avmetadata[:topic] || matching_avmetadata[:keyword])
                   combined_keywords = [matching_avmetadata[:satisfies], matching_avmetadata[:topic], matching_avmetadata[:keyword]].compact.join('; ')
                   combined_keywords.split(/[,;]\s*/).join(', ') # Split by both commas and semicolons, then join with commas
                 elsif matching_chapter
                   matching_chapter # Use the chapter name if there are no specific keywords
                 else
                   exercise.name # or fallback to using the exercise's name as the keyword, if there are no specific keywords
                 end

      {
        "Platform_name": "OpenDSA",
        "URL": exercise.embed_url(host_url),
        "LTI_Instructions_URL": "https://opendsa-server.cs.vt.edu/guides/lti-instructions",
        "Exercise_type": exercise.ex_type,
        "License": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)",
        "Description": exercise.description,
        "Author": "Shaffer",
        "Institution": "Virginia Tech",
        "Keywords": keywords,
        "Exercise_Name": exercise.name,
        "Iframe_URL": exercise.embed_url(host_url),
        "LTI_URL": "#{host_url}/lti/launch?custom_ex_short_name=#{exercise.short_name}"
      }
    end.compact

    render json: export_data
  end
end