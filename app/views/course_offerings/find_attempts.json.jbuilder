json.set! :odsa_exercise_attempts, @odsa_exercise_attempts
# chapters
@odsa_exercise_attempts.collect do |d|
    json.set! :id, d.id
    json.set! :user_id, d.user_id
    json.set! :question_name, d.question_name
    json.set! :request_type, d.request_type
    json.set! :correct, d.correct
    json.set! :worth_credit, d.worth_credit
    json.set! :time_done, d.time_done
    json.set! :time_taken, d.time_taken
    json.set! :earned_proficiency, d.earned_proficiency
    json.set! :pe_score, d.pe_score
    json.set! :pe_steps_fixed, d.pe_steps_fixed
  end
# json.set! :question_name, @odsa_exercise_attempts.question_name
# json.set! :request_type, @odsa_exercise_attempts.request_type
# json.set! :correct, @odsa_exercise_attempts.correct
# json.set! :worth_credit, @odsa_exercise_attempts.worth_credit
# json.set! :time_done, @odsa_exercise_attempts.time_done.try(:strftime, "%Y-%m-%d %H:%m:%S")
# json.set! :time_taken, @odsa_exercise_attempts.time_taken.try(:strftime, "%Y-%m-%d %H:%m:%S")
# json.set! :earned_proficiency, @odsa_exercise_attempts.earned_proficiency
# json.set! :points_earned, @odsa_exercise_attempts.points_earned
# json.set! :pe_score, @odsa_exercise_attempts.pe_score
# json.set! :pe_steps_fixed, @odsa_exercise_attempts.pe_steps_fixed
#"id, user_id, question_name, request_type,
#correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
#pe_score, pe_steps_fixed")
puts "///////////////////////////////////////////////////////"
#puts "printing inspect #{@odsa_exercise_progress.inspect}"
json.set! :odsa_exercise_progress, @odsa_exercise_progress
@odsa_exercise_progress.collect do |d|
    json.set! :user_id, d.user_id
    json.set! :current_score, d.current_score
    json.set! :highest_score, d.highest_score
    json.set! :total_correct, d.total_correct
    json.set! :proficient_date, d.proficient_date
    json.set! :first_done, d.first_done
    json.set! :last_done, d.last_done
end

#user_id, current_score, highest_score,
# total_correct, proficient_date,first_done, last_done"
# json.set! :inst_book_id, @inst_book.id
# json.set! :title, @inst_book.title
# json.set! :desc, @inst_book.desc
# json.set! :last_compiled, @inst_book.last_compiled.try(:strftime, "%Y-%m-%d %H:%m:%S")

# options = @odsa_exercise_progress.options
# if options != nil && options != "null"
#   options = eval(options)
#   options.each do |key, value|
#     json.set! key, value
#   end
# end
# options = @odsa_exercise_attempts.options
# if options != nil && options != "null"
#   options = eval(options)
#   options.each do |key, value|
#     json.set! key, value
#   end
# end

  puts "time"