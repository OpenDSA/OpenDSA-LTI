class InstModuleSectionExercise < ActiveRecord::Base
    belongs_to :inst_module_section, inverse_of: :inst_module_section_exercises
    belongs_to :inst_exercise
    has_many :odsa_user_interactions, dependent: :destroy
    has_many :odsa_exercise_attempts, dependent: :destroy
    has_many :odsa_exercise_progresses, dependent: :destroy
end
