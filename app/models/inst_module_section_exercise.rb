class InstModuleSectionExercise < ActiveRecord::Base
    belongs_to :inst_module_version, inverse_of: :inst_module_section_exercises
    belongs_to :inst_module_section, inverse_of: :inst_module_section_exercises
    belongs_to :inst_exercise
    has_many :odsa_user_interactions, dependent: :destroy
    has_many :odsa_exercise_attempts, dependent: :destroy
    has_many :odsa_exercise_progresses, dependent: :destroy

    def self.save_data_from_json(inst_module_version, inst_module_section, exercise_name, json)
        ex = InstExercise.find_by(short_name: exercise_name)
        if ex.nil?
            ex = InstExercise.new(
                short_name: exercise_name,
                ex_type: json['type']
            )
            if json['learning_tool']
                ex.name = exercise_name
                ex.learning_tool = json['learning_tool']
            elsif json['long_name']
                ex.name = json['long_name']
            end
            ex.save!
        elsif ex.ex_type.blank?
            ex.ex_type = json['type']
            ex.save!
        end

        inst_mod_sec_ex = InstModuleSectionExercise.new(
            inst_module_version: inst_module_version,
            inst_module_section: inst_module_section,
            inst_exercise: ex
        )
        inst_mod_sec_ex.points = json['points'] || 0
        inst_mod_sec_ex.required = json['required'] || false
        if json['type'] == 'pe'
            inst_mod_sec_ex.threshold = json['threshold'] || 1
        elsif json['type'] == 'extr'
            inst_mod_sec_ex.threshold = json['threshold'] || 100
        else
            inst_mod_sec_ex.threshold = json['threshold'] || 5
        end
        if json.key?('exer_options')
            inst_mod_sec_ex.options = json['exer_options'].to_json
        end
        inst_mod_sec_ex.save!
    end
end
