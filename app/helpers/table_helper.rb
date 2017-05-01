module TableHelper #< Mustache
	#require 'mustache'
	#self.template_path = __dir__

	#def initialize (odsa_exercise_attempts, odsa_exercise_progress)
	def self.arg (odsa_exercise_attempts, odsa_exercise_progress)
		@odsa_exercise_attempts = odsa_exercise_attempts
		@odsa_exercise_progress  = odsa_exercise_progress
	end
	def attempts
		@odsa_exercise_attempts.collect! do |d|
			d.attributes.each do |x|
				puts x
			end
		end
		return @odsa_exercise_attempts
	end
	def progress
		return @odsa_exercise_progress
	end
	def hint_used
		puts "getting hint for template_path with #{@odsa_exercise_attempts.hint_used}"
		return @odsa_exercise_attempts.hint_used
	end
	def count_attempts
		puts "getting count_attempts for template_path"
		return @odsa_exercise_attempts.count_attempts
	end
	def earned_proficiency
		puts "getting earned_proficiency for template_path"
		return @odsa_exercise_attempts.earned_proficiency
	end
	def time_done
		puts "getting time_done for template_path"
		return @odsa_exercise_attempts.time_done
	end
	def current_score
		puts "getting cuurent score"
		return @odsa_exercise_progress.current_score
	end
	def highest_score
		puts "highest_score"
		return @odsa_exercise_progress.highest_score
	end
	def first_done
		puts "getting first_done for template_path"
		return @odsa_exercise_progress.first_done
	end
	def last_done
		puts "getting time_done for template_path"
		return @odsa_exercise_progress.last_done
	end
	def total_correct
		puts "getting total_correct for template_path"
		return @odsa_exercise_progress.total_correct
	end
	def proficient_date
		puts "getting proficient_date for template_path"
		return @odsa_exercise_progress.proficient_date
	end
	def correct_exercises
		puts "getting correct_exercises for template_path #{@odsa_exercise_progress.correct_exercises}"
		return @odsa_exercise_progress.correct_exercises
	end

end
