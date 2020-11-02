class BookDataDownloadsController < ApplicationController
  def show
    @book = InstBook.find_by_id(params[:id])
    @book_id = params[:id]
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
      format.html
      format.csv do
        if(params[:type] == "attempt") then
          send_data @ex_attempts.to_csv, filename: "exercises-attempts-#{@book.title}.csv"
        end
        if(params[:type] == "progress") then
          send_data @ex_progresses.to_csv, filename: "exercise-progresses-#{@book.title}.csv"
        end
        if(params[:type] == "md_progress") then
          send_data @md_progresses.to_csv, filename: "module-progresses-#{@book.title}.csv"
        end
        if(params[:type] == "interaction") then
          send_data @interactions.to_csv, filename: "interactions-#{@book.title}.csv"
        end
      end
      format.json do
        if(params[:type] == "attempt") then
          send_data @ex_attempts.to_json, :type => 'application/json; header=present', filename: "exercises-attempts-#{@book.title}.json"
        end
        if(params[:type] == "progress") then
          send_data @ex_progresses.to_json, :type => 'application/json; header=present', filename: "exercises-progresses-#{@book.title}.json"
        end
        if(params[:type] == "md_progress") then
          send_data @md_progresses.to_json, :type => 'application/json; header=present', filename: "module-progresses-#{@book.title}.json"
        end
        if(params[:type] == "interaction") then
          send_data @interactions.to_json, :type => 'application/json; header=present', filename: "interactions-#{@book.title}.json"
        end
      end
    end
  end
end
