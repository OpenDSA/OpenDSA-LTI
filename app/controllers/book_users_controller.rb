class BookUsersController < ApplicationController
  def index
  end
  def show
    @book = InstBook.find_by_id(params[:book_data_download_id])
    @user = User.find_by_id(params[:id])
    @ex_attempts = OdsaExerciseAttempt.where(inst_book_id: params[:book_data_download_id], user_id: params[:id])
    @book_section_exercise = InstBookSectionExercise.where(inst_book_id: params[:book_data_download_id])
    @ex_progresses = Array.new
    @book_section_exercise.each do |exercise|
      @progress = OdsaExerciseProgress.where(inst_book_section_exercise_id: exercise.id, user_id: params[:id])
      @ex_progresses.concat @progress
    end
    @ex_progresses = OdsaExerciseProgress.where(id: @ex_progresses.map(&:id))
    @interactions = OdsaUserInteraction.where(inst_book_id: params[:book_data_download_id], user_id: params[:id])

    respond_to do |format|
      format.html
      format.csv do
        if(params[:type] == "attempt") then
          if (@ex_attempts.length() == 0) then
            render(
                html: "<script>alert('Empty List!')</script>".html_safe,
                layout: 'application'
            )
          else
            send_data @ex_attempts.to_csv, filename: "exercises-attempts-#{@book.title}-#{@user.id}.csv"
          end
        end
        if(params[:type] == "progress") then
          if (@ex_progresses.length() == 0) then
            render(
                html: "<script>alert('Empty List!')</script>".html_safe,
                layout: 'application'
            )
          else
            send_data @ex_progresses.to_csv, filename: "exercise-progresses-#{@book.title}.csv"
          end
        end
        if(params[:type] == "interaction") then
          if (@interactions.length() == 0) then
            render(
                html: "<script>alert('Empty List!')</script>".html_safe,
                layout: 'application'
            )
          else
            send_data @interactions.to_csv, filename: "interactions-#{@book.title}.csv"
          end
        end
      end
      format.json do
        if(params[:type] == "attempt") then
          send_data @ex_attempts.to_json, :type => 'application/json; header=present', filename: "exercises-attempts-#{@book.title}.json"
        end
        if(params[:type] == "progress") then
          send_data @ex_progresses.to_json, :type => 'application/json; header=present', filename: "exercises-progresses-#{@book.title}.json"
        end
        if(params[:type] == "interaction") then
          send_data @interactions.to_json, :type => 'application/json; header=present', filename: "interactions-#{@book.title}.json"
        end
      end
    end
  end
end
