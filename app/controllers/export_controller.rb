class ExportController < ApplicationController
  # GET /export
  # gives an export of opendsa embeddable slideshows and exercises
  # with iframe and lti links for SPLICE
  def index
    host_url = request.base_url
    inst_book = InstBook.first
    raise "InstBook instance not found" unless inst_book

    av_data = inst_book.extract_av_data_from_rst
    @exercises = InstExercise.all
    export_count = 0 # Initialize the export counter for debugging purposes

    export_data = @exercises.map do |exercise|
      matching_chapter = nil
      matching_avmetadata = nil

      av_data.each do |chapter, data|
        if data[:inlineav]&.include?(exercise.short_name) || data[:avembed]&.include?(exercise.short_name)
          matching_avmetadata = data[:avmetadata]
          matching_chapter = chapter
          export_count += 1
          break
        end
      end

      keywords = if matching_avmetadata && (matching_avmetadata[:satisfies] || matching_avmetadata[:topic] || matching_avmetadata[:keyword])
                   [matching_avmetadata[:satisfies], matching_avmetadata[:topic], matching_avmetadata[:keyword]].compact.join(', ')
                 else
                   matching_chapter # use book chapter name if there no keywords
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