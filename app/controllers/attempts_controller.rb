class AttemptsController < ApplicationController
   
    def show
        @attempts = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt")
        @questions = Array.new
        @attempts.each do |att|
            @questions << att.question_name
        end
        
        @count = Array.new
    
        @questions.each do |q|
            @count << OdsaExerciseAttempts.where(question_name: q, request_type: "hint").count
        end

        @hint = OdsaExerciseAttempts.group("question_name").where(request_type: "hint")
        @hint_count = OdsaExerciseAttempts.group("question_name").where(request_type: "hint")
        @hint_max = @hint_count.max
        @incorrect_attempt = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt", correct: "0")
    end

    # Use to show the exercise page
    def exercise
        @attempts = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt")
        @questions = Array.new
        @attempts.each do |att|
            @questions << att.question_name
        end
        @attempts_count = @attempts.count
        @attempts_max = @attempts.count.values.max
        @attempts_division = Array.new
        @attempts_count.each do |n|
            @attempts_division << n[1].to_f / @attempts_max.to_f * 100
        end

        @hints = OdsaExerciseAttempts.group("question_name").where(request_type: "hint")
        @hints_questions = Array.new
        @hints.each do |att|
            @hints_questions << att.question_name
        end
        @hints_count = @hints.count
        @hints_max = @hints.count.values.max
        @hints_division = Array.new
        @hints_count.each do |n|
            @current_attempts = OdsaExerciseAttempts.where(question_name: n[0], request_type: "attempt").count
            @hints_division << n[1].to_f / @current_attempts.to_f * 100
        end

        @incorrects = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt", correct: "0")
        @incorrects_questions = Array.new
        @incorrects.each do |att|
            @incorrects_questions << att.question_name
        end

        @incorrects_count = @incorrects.count
        @incorrects_max = @incorrects.count.values.max
        @incorrects_division = Array.new
        @current_attempt = Array.new
        @incorrects_count.each do |n|
            @current_attempt = OdsaExerciseAttempts.where(question_name: n[0], request_type: "attempt").count
            @incorrects_division << n[1].to_f /  @current_attempt.to_f * 100
           
        end

        #render inline: "
        #attempt <%= @questions.count %>
        #incorrects_questions <%= @incorrects_questions.count %>
        #count <%=@incorrects_count %>
        #attempt - max <%=  @attempts_max %>
        #max <%=  @incorrects_max %>
        #division <%= @incorrects_division %>
        #current questions <%= @current_attempt %>"
    end

    def student_exercise_attempt
        @attempts = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt")
        @questions = Array.new
        @attempts.each do |att|
            @questions << att.question_name
        end
        @books = OdsaExerciseAttempts.group("inst_book_id").where(request_type: "attempt")
        @books_name = Array.new
        @books.each do |b|
            @books_name << b.inst_book_id
        end
    end

    def index
        @attempts = OdsaExerciseAttempts.group("question_name")
        @questions = Array.new
        @attempts.each do |att|
            @questions << att.question_name
        end
        
        @count = Array.new
    
        @questions.each do |q|
            @count << OdsaExerciseAttempts.where(question_name: q, request_type: "hint").count
        end

        @hint = @attempts.where(request_type: "hint")
        @incorrect_attempt = @attempts.where(request_type: "attempt", correct: "0")
    end

    def incorrect_graph
        @incorrect_attempt = OdsaExerciseAttempts.group("question_name").where(request_type: "attempt", correct: "0")  
    end

    def hint_graph
        @hint = OdsaExerciseAttempts.group("question_name").where(request_type: "hint")
    end

    def attempts_graph
        @attempts = OdsaExerciseAttempts.group("question_name")
    end

    def get_book_user_attempts_information
        @attempt = OdsaExerciseAttempts.where(inst_book_id: params[:inst_book_id], user_id: params[:user_id], request_type: "attempt").count
        @incorrect_answers = OdsaExerciseAttempts.where(inst_book_id: params[:inst_book_id], user_id: params[:user_id], request_type: "attempt", correct: 0).count
        @hint_usage = OdsaExerciseAttempts.where(inst_book_id: params[:inst_book_id], user_id: params[:user_id], request_type: "hint").count
        render inline: 
        "Book id: <%= params[:inst_book_id] %> <br>
        User id:  <%= params[:user_id] %> <br>
        Attempts: <%= @attempt %> <br>
        Incorrect Answers : <%= @incorrect_answers %> <br>
        Hint Usage : <%= @hint_usage %>"
    end

    def get_book_user_interation_exercise_total_time
        @interations =(OdsaUserInteractions.where(inst_book_id: params[:inst_book_id], user_id: params[:user_id],name: "jsav-forward")
        .or(OdsaUserInteractions.where(inst_book_id: params[:inst_book_id], user_id: params[:user_id],name: "jsav-backward"))).order(:action_time)
        
        temp = @interations[0]
        current_time = 0.0
        exercise_time_array = Hash.new()
        sameOutput = false
        @total_time = 0.0

        @interations.each do |interation|
            if interation.inst_book_section_exercise_id == temp.inst_book_section_exercise_id
                time = interation.action_time - temp.action_time
                @total_time = @total_time + time
                sameOutput = true
            else
                time = 0
                sameOutput = false
            end
            temp = interation
        end

        render inline:
        "Book id: <%= params[:inst_book_id] %> <br>
        User id:  <%= params[:user_id] %> <br>
        Total Time : <%= @total_time %>
        "
    end

    # For each exercise, how many student attempt it
    def get_exercise_student_attempt
        @student_attempt = OdsaExerciseAttempts.where(question_name: params[:question_name], ).group_by(&:user_id).count
        render inline:
        "id: <%= @student_attempt %>"
    end

    #for each question, how many incorrect attempts
    def get_question_incorrect
        @question = OdsaExerciseAttempts.where(question_name: params[:question_name], request_type: "attempt", correct: "0").count
        render inline: "count <%= @question %>"
    end

    #for each question, how many hint were used
    def get_question_hint
        @question = OdsaExerciseAttempts.where(question_name: params[:question_name], request_type: "hint").count
        
        render inline: "count <%= @question %>"
    end
end