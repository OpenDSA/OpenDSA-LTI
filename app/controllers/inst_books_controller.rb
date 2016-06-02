class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # GET /exercises
  def index
    @exercises = Exercise.where(is_public: true)
  end


  # -------------------------------------------------------------
  # GET /exercises/download.csv
  def download
    @exercises = Exercise.accessible_by(current_ability)

    respond_to do |format|
      format.csv
      format.json do
        render text:
          ExerciseRepresenter.for_collection.new(@exercises).to_hash.to_json
      end
      format.yml do
        render text:
          ExerciseRepresenter.for_collection.new(@exercises).to_hash.to_yaml
      end
    end
  end


  # -------------------------------------------------------------
  def search
    @terms = escape_javascript(params[:search])
    @terms = @terms.split(@terms.include?(',') ? /\s*,\s*/ : nil)
#    @wos = Workout.search @terms
    @wos = []
    @exs = Exercise.search(@terms, current_user)
    @msg = ''
#    if @wos.length == 0 && @exs.length == 0
    if @exs.length == 0
      @msg = 'No exercises were found for your search request. ' \
        'Try these instead...'
#      @wos = Workout.order('RANDOM()').limit(4)
      @exs = Exercise.order('RANDOM()').limit(16)
    end
    if @exs.length == 0
      @msg = 'No public exercises are available to search right now. ' \
        'Wait for contributors to add more.'
    end
  end


  # -------------------------------------------------------------
  # GET /exercises/1
  def show
    # respond_to do |format|
    #   format.html
    #   format.json {render json: @inst_book}
    # end
  end


  # -------------------------------------------------------------
  # GET /exercises/new
  def new
    @exercise = Exercise.new
    # @coding_exercise = CodingQuestion.new
    # @languages = Tag.where(tagtype: Tag.language).pluck(:tag_name)
    # @areas = Tag.where(tagtype: Tag.area).pluck(:tag_name)
  end


  # -------------------------------------------------------------
  # GET /exercises/1/edit
  def edit
  end

  # -------------------------------------------------------------
  # POST /exercises
  def create
    ex = Exercise.new
    exercise_version = ExerciseVersion.new(exercise: ex)
    msg = params[:exercise] || params[:coding_question]
    msg[:is_public] = msg[:is_public].to_i > 0
    form_hash = msg.clone()
    arr = []
    form_hash["current_version"] = msg[:exercise_version].clone()
    if msg[:question_type].to_i == 2
      msg[:coding_prompt].merge!(msg[:prompt])
      test_cases = ""
      msg[:coding_prompt][:test_cases_attributes].values.each do |tc|
        test_cases = test_cases + tc.values.join(",") + "\n"
      end
      test_cases.rstrip!
      msg[:coding_prompt].delete("test_cases_attributes")
      msg[:coding_prompt]["tests"] = test_cases
      form_hash["current_version"]["prompts"] = Array.new
      codingprompt = {"coding_prompt" => msg[:coding_prompt].clone()}
      form_hash["current_version"]["prompts"] << codingprompt
      form_hash.delete("coding_prompt")
    elsif msg[:question_type].to_i == 1
      msg[:multiple_choice_prompt].merge!(msg[:prompt])
      msg[:multiple_choice_prompt][:is_scrambled] = msg[:multiple_choice_prompt][:is_scrambled].to_i > 0
      msg[:multiple_choice_prompt][:allow_multiple] = msg[:allow_multiple].to_i > 0
      form_hash["current_version"]["prompts"] = Array.new
      msg[:multiple_choice_prompt]["choices"] = msg[:multiple_choice_prompt]["choices"].values
      multiplechoiceprompt = {"multiple_choice_prompt" => msg[:multiple_choice_prompt].clone()}
      form_hash["current_version"]["prompts"] << multiplechoiceprompt
      form_hash.delete("multiple_choice_prompt")
    end
    form_hash.delete("prompt")
    form_hash.delete("exercise_version")
    form_hash.delete("question_type")
    arr << form_hash
    exercises = ExerciseRepresenter.for_collection.new([]).from_hash(arr)
    if exercises[0].save!
      redirect_to ex, notice: 'Exercise was successfully created.'
    else
      #render action: 'new'
      redirect_to ex, notice:
        "Exercise was NOT created for #{msg} #{@exercise.errors.messages}"
    end
  end


  # -------------------------------------------------------------
  def random_exercise
    exercise_dump = []
    Exercise.where(is_public: true).each do |exercise|
      if params[:language] ?
        (exercise.language == params[:language]) :
        params[:question_type] ?
        (exercise.question_type == params[:question_type].to_i) :
        true

        exercise_dump << exercise
      end
    end
    redirect_to exercise_practice_path(exercise_dump.sample) and return
  end


  # -------------------------------------------------------------
  # POST exercises/create_mcqs
  def create_mcqs
    CSV.foreach(params[:form].fetch(:mcqfile).path, {headers: true}) do |row|
      if row['Question'].include?('Python')
        next
      end
      exercise = Exercise.new(external_id: row['ID'])
      exercise.is_public = false
      exercise.language = ''
    end
  end# def


  # -------------------------------------------------------------
  # GET exercises/upload_mcqs
  def upload_mcqs
  end


  # -------------------------------------------------------------
  # GET exercises/upload_exercises
  def upload
  end


  # -------------------------------------------------------------
  def upload_yaml
  end


  # -------------------------------------------------------------
  def yaml_create
    @yaml_exers = YAML.load_file(params[:form].fetch(:yamlfile).path)
    @yaml_exers.each do |exercise|
      @ex = Exercise.new
      @ex.name = exercise['name']
      @ex.external_id = exercise['external_id']
      @ex.is_public = exercise['is_public']
      @ex.experience = exercise['experience']
      exercise['language_list'].split(",").each do |lang|
        print "\nLanguage: ", lang
      end
      exercise['style_list'].split(",").each do |style|
        print "\nStyle: ", style
      end
      exercise['tag_list'].split(",").each do |tag|
        print "\nTag: ", tag
      end
      version = exercise['current_version']
      @ex.versions = version['version']
      @ex.save!
      @version = ExerciseVersion.new(exercise: @ex,creator_id:
                 User.find_by(email: version['creator']).andand.id,
                 exercise: @ex,
                 position:1)
      @version.save!
      version['prompts'].each do |prompt|
        prompt = prompt['coding_prompt']
        @prompt = CodingPrompt.new(exercise_version: @version)
        @prompt.question = prompt['question']
        @prompt.position = prompt['position']
        @prompt.feedback = prompt['feedback']
        @prompt.class_name = prompt['class_name']
        @prompt.method_name = prompt['method_name']
        @prompt.starter_code = prompt['starter_code']
        @prompt.wrapper_code = prompt['wrapper_code']
        @prompt.test_script = prompt['tests']
        @prompt.actable_id = rand(100)
        @prompt.save!
      end

    end
    redirect_to exercises_path
  end


  # -------------------------------------------------------------
  # POST /inst_books/upload_create
  def upload_create
    hash = JSON.load(File.read(params[:form][:file].path))
    InstBook.save_data_from_json(hash)


    redirect_to inst_books_url + '/upload', notice: 'Book configuration upload complete.'
  end

  # -------------------------------------------------------------
  # POST /inst_books/:id/compile
  def compile
    launch_url = request.protocol + request.host_with_port + "/lti/launch"
    @job = Delayed::Job.enqueue CompileBookJob.new(params[:id], launch_url, current_user.id)

    # respond_to do |format|
    #   format.js
    # end

    # render :template => 'inst_books/compile.js.haml'
    # render :partial => 'compile.js.haml'
    # redirect_to :back, notice: 'Book was compiled successfully!.'
  end

  #~ Private instance methods .................................................
  private
    # -------------------------------------------------------------
    def create_new_version
      newexercise = Exercise.new
      newexercise.name = @exercise.name
      newexercise.creator_id = current_user.id
      newexercise.question = @exercise.question
      newexercise.feedback = @exercise.feedback
      newexercise.is_public = @exercise.is_public
      newexercise.mcq_allow_multiple = @exercise.mcq_allow_multiple
      newexercise.mcq_is_scrambled = @exercise.mcq_is_scrambled
      newexercise.priority =  @exercise.priority
      # TODO: Get the count of attempts from the session
      newexercise.count_attempts = 0
      newexercise.count_correct = 0
      newexercise.experience = @exercise.experience
      newexercise.version = @exercise.base_exercise.versions =
        @exercise.version + 1
      # default IRT statistics
      newexercise.difficulty = 5
      newexercise.discrimination = @exercise.discrimination
      return newexercise
    end

    # -------------------------------------------------------------
    # Only allow a trusted parameter "white list" through.
    def exercise_params
      params.require(:exercise).permit(:name, :question, :feedback,
        :experience, :id, :is_public, :priority, :question_type,
        :exercise_version, :exercise_version_id, :commit,
        :mcq_allow_multiple, :mcq_is_scrambled, :languages, :styles,
        :tag_ids)
    end

    # -------------------------------------------------------------
    def count_submission
      if !session[:exercise_id] ||
        session[:exercise_id] != params[:id] ||
        !session[:submit_num]

        # TODO: look up only current user
        recent = Attempt.where(user_id: 1).where(
          exercise_version_id: params[:exercise_version_id]).
          sort_by { |a| a[:submit_num] }
        if !recent.empty?
          session[:submit_num] = recent.last[:submit_num] + 1
        else
          session[:submit_num] = 1
        end
      else
        session[:submit_num] +=  1
      end
    end

end
