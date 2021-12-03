class ResendScoresJob < ProgressJob::Base
  def initialize(user_id, inst_book_id)
    @user_id = user_id
    @inst_book = InstBook.find_by(id: inst_book_id)
  end

  def perform
    # Just picking the first inst_exercise, since it doesn't seem to matter
    ex = @inst_book.inst_book_section_exercises.first.andand.inst_exercise
    @inst_book.odsa_module_progresses.each do |prog|
      # force score update, exercise doesn't matter
      prog.update_proficiency(ex, true)
    end
  end

end
