class OdsaExerciseAttemptsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

# sha1:IntroSumm
# seed:168
# problem_type:IntroMCQgoalsp
# key:phantom-key
# inst_book_id:1
# inst_section_id:1
# module_name:IntroDSA
# casing:camel
# complete:1
# count_hints:0
# time_taken:37
# attempt_number:1
# attempt_content:{"isNone":null,"value":"How to design and maintain large programs","index":0}
# skipped:0
# opt_out:0
# client_dt:2016-06-26T14:17:47-04:00
# code:
# genlist:
# summexname:
# checkdefvar:
# listoftypes:
# progexType:
  # -------------------------------------------------------------
  # POST /odsa_exercise_attempts/attempt
  def attempt
    print params
    inst_book = InstBook.find_by(id: params[:inst_book_id])
    inst_section = InstSection.find_by(id: params[:inst_section_id])
    inst_exercise = InstExercise.find_by(short_name: params[:sha1])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                              "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                                params[:inst_book_id], inst_section.id, inst_exercise.id).first

    question_name = params['problem_type']
    if params[:non_summative]
      question_name = params[:non_summative]
    end

    @exercise_attempt = OdsaExerciseAttempt.new(
                                          inst_book: inst_book,
                                          user: current_user,
                                          inst_section: inst_section,
                                          inst_book_section_exercise: inst_book_section_exercise,
                                          correct: params[:correct],
                                          time_done: Time.now,
                                          time_taken: params[:time_taken],
                                          count_hints: params[:count_hints],
                                          hint_used: params[:count_hints].to_i > 0,
                                          question_name: question_name,
                                          request_type: "attempt",
                                          points_earned: 1,
                                          earned_proficiency: true,
                                          ip_address: request.ip)

    respond_to do |format|
      if @exercise_attempt.save
        msg = { :status => "ok", :message => "Success!" }
      else
        msg = { :status => "fail", :message => "Fail!" }
      end
      format.json  { render :json => msg }
    end
  end

  #~ Private instance methods .................................................
end
