class ExportController < ApplicationController
  # GET /export
  # gives an export of opendsa embeddable slideshows and exercises
  # with iframe and lti links for SPLICE
  def index
    host_url = request.base_url
    inst_book = InstBook.first
    raise "InstBook instance not found" unless inst_book

    # extract avmetadata data from the RST files in opendsa/rst and fetch exercises inst_exercises
    av_data = inst_book.extract_av_data_from_rst
    @exercises = InstExercise.all
    export_count = 0 # Initialize the export counter 
    matched_exercises = [] # store the details of matched exercises

    # initialize counters for matching keywords
    matched_with_keywords_count = 0
    matched_with_inlineav_and_shortname_count = 0

    # map each exercise to its export data.
    export_data = @exercises.map do |exercise|
      matching_chapter = nil # Store the chapter name
      matching_avmetadata = nil

      av_data.each do |chapter, data|
        if data[:inlineav]&.include?(exercise.short_name)
          matching_avmetadata = data[:avmetadata]
          matching_chapter = chapter
          matched_exercises << { exercise_name: exercise.name, chapter: chapter, keywords: matching_avmetadata }
          matched_with_inlineav_and_shortname_count += 1

          matched_with_keywords_count += 1 unless matching_avmetadata.nil? || matching_avmetadata[:keywords].nil? || matching_avmetadata[:keywords].empty?
          export_count += 1
          break
        end
      end

      # Construct the keywords from avmetadata, else use chapter name.
      keywords = if matching_avmetadata && (matching_avmetadata[:satisfies] || matching_avmetadata[:topic] || matching_avmetadata[:keyword])
                   [matching_avmetadata[:satisfies], matching_avmetadata[:topic], matching_avmetadata[:keyword]].compact
                 else
                   [matching_chapter] # use chapter name if there no keywords
                 end

      # Construct the export data for the exercise.
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

    # p "Total exports processed: #{export_count}"

    render json: export_data
  end
end



