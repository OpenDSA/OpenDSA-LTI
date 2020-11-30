class BookDataDownloadsController < ApplicationController
  include BookDataDownloadsHelper

  def show
    @book = InstBook.find_by_id(params[:book_id])
    @ex_attempts = OdsaExerciseAttempt.where(inst_book_id: @book.id)
    @book_section_exercise = InstBookSectionExercise.where(inst_book_id: @book.id)
    @ex_progresses = Array.new
    @book_section_exercise.each do |exercise|
      @progress = OdsaExerciseProgress.where(inst_book_section_exercise_id: exercise.id)
      @ex_progresses.concat @progress
    end
    @ex_progresses = OdsaExerciseProgress.where(id: @ex_progresses.map(&:id))
    @md_progresses = OdsaModuleProgress.where(inst_book_id: @book.id)
    @interactions = OdsaUserInteraction.where(inst_book_id: @book.id)
    @book_id = params[:book_id]
    @attributes_list = Array.new
    @attributes_list = combine_attributes(@ex_attempts, "attempt", @attributes_list)
    @attributes_list = combine_attributes(@ex_progresses, "prog", @attributes_list)
    @attributes_list = combine_attributes(@interactions, "interaction", @attributes_list)
    @attempt_desc = attempt_attr_desc
    @progress_desc = progress_attr_desc
    @interaction_desc = interaction_attr_desc

    session[:curr_book] = @book_id
  end
  def index
    @book_id = session[:curr_book]
    @book = InstBook.find_by_id(@book_id)
    @ex_attempts = OdsaExerciseAttempt.where(inst_book_id: @book.id)
    @book_section_exercise = InstBookSectionExercise.where(inst_book_id: @book.id)
    @ex_progresses = Array.new
    @book_section_exercise.each do |exercise|
      @progress = OdsaExerciseProgress.where(inst_book_section_exercise_id: exercise.id)
      @ex_progresses.concat @progress
    end
    @ex_progresses = OdsaExerciseProgress.where(id: @ex_progresses.map(&:id))
    @md_progresses = OdsaModuleProgress.where(inst_book_id: @book.id)
    @interactions = OdsaUserInteraction.where(inst_book_id: @book.id)

    respond_to do |format|
      param_array = Array.new
      params.each do |k, v|
        if(v['result'])
          if (v['result'] == '1')
            param_array.push(k)
          end
        end
      end
      format.html
      format.csv do
        if(params[:type] == "attempt") then
          send_data to_csv([@ex_attempts, param_array]), filename: "exercises-attempts-#{@book.title}.csv"
        end
        if(params[:type] == "progress") then
          send_data to_csv([@ex_progresses, param_array]), filename: "exercise-progresses-#{@book.title}.csv"
        end
        if(params[:type] == "md_progress") then
          send_data @md_progresses.to_csv, filename: "module-progresses-#{@book.title}.csv"
        end
        if(params[:type] == "interaction") then
          send_data ([@interactions, param_array]), filename: "interactions-#{@book.title}.csv"
        end
      end
      format.json do
        if(params[:type] == "attempt") then
          send_data @ex_attempts.to_json(:only => param_array ), :type => 'application/json; header=present', filename: "exercises-attempts-#{@book.title}.json"
        end
        if(params[:type] == "progress") then
          send_data @ex_progresses.to_json(:only => param_array), :type => 'application/json; header=present', filename: "exercises-progresses-#{@book.title}.json"
        end
        if(params[:type] == "md_progress") then
          send_data @md_progresses.to_json(:only => param_array), :type => 'application/json; header=present', filename: "module-progresses-#{@book.title}.json"
        end
        if(params[:type] == "interaction") then
          send_data @interactions.to_json(:only => param_array), :type => 'application/json; header=present', filename: "interactions-#{@book.title}.json"
        end
      end
    end
  end
  def list_users
    @book_id = params[:book_id]
    @ex_attempts = OdsaExerciseAttempt.where(inst_book_id: params[:book_id])
    @book_section_exercise = InstBookSectionExercise.where(inst_book_id: params[:book_id])
    @ex_progresses = Array.new
    @book_section_exercise.each do |exercise|
      puts exercise.id
      @progress = OdsaExerciseProgress.where(inst_book_section_exercise_id: exercise.id)
      @ex_progresses.concat @progress
    end
    @interactions = OdsaUserInteraction.where(inst_book_id:params[:book_id])

    @users = Array.new
    @ex_attempts.each do |exercise|
      unless @users.include?(exercise.user_id)
        puts exercise.user_id
        @users.push(exercise.user_id)
      end
    end
    @ex_progresses.each do |progress|
      unless @users.include?(progress.user_id)
        puts progress.user_id
        @users.push(progress.user_id)
      end
    end
    @interactions.each do |interaction|
      unless @users.include?(interaction.user_id)
        puts interaction.user_id
        @users.push(interaction.user_id)
      end
    end

    @user_records = Array.new
    @users.each do |user|
      @usr = User.find_by_id(user)
      @user_records.push(@usr)
    end
  end
end
