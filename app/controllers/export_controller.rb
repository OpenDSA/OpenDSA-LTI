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

      # using array for keywords 
      keywords = if matching_avmetadata && (matching_avmetadata[:satisfies] || matching_avmetadata[:topic] || matching_avmetadata[:keyword])
                   [matching_avmetadata[:satisfies], matching_avmetadata[:topic], matching_avmetadata[:keyword]].compact.flat_map { |k| k.split(/[,;]\s*/) }
                 elsif matching_chapter
                   [matching_chapter] # Use the chapter name if there are no specific keywords
                 else
                   [exercise.name] # Fallback to using the exercise's name as the keyword, if there are no specific keywords
                 end

      {
        "catalog_type": "SLCItemCatalog",
        "platform_name": "OpenDSA",
        "url": exercise.embed_url(host_url),
        "lti_instructions_url": "https://opendsa-server.cs.vt.edu/guides/opendsa-canvas",
        "exercise_type": exercise.ex_type,
        "license": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)",
        "description": exercise.description,
        "author": "Cliff Shaffer",
        "institution": "Virginia Tech",
        "keywords": keywords, 
        "exercise_name": exercise.name,
        "iframe_url": exercise.embed_url(host_url),
        "lti_url": "#{host_url}/lti/launch?custom_ex_short_name=#{exercise.short_name}&custom_ex_settings=%7B%7D"
      }
    end.compact

    render json: export_data
  end
end
