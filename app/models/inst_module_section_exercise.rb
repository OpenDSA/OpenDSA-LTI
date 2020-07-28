# frozen_string_literal: true

# an \exercise in a stand-alone module
class InstModuleSectionExercise < ApplicationRecord

  belongs_to :inst_module_version, inverse_of: :inst_module_section_exercises
  belongs_to :inst_module_section, inverse_of: :inst_module_section_exercises
  belongs_to :inst_exercise
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :odsa_exercise_attempts, dependent: :destroy
  has_many :odsa_exercise_progresses, dependent: :destroy

  def self.save_data_from_json(inst_module_version, inst_module_section, exercise_name, json)
    ex = InstExercise.find_by(short_name: exercise_name)
    save_ex = false
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
      save_ex = true
    elsif ex.ex_type.blank? || ex.ex_type != json['type']
      ex.ex_type = json['type']
      save_ex = true
    end

    if json.include?('av_address')
      ex.av_address = json['av_address']
      dimensions = InstExercise.get_av_dimensions(ex.av_address)
      unless dimensions.nil?
        ex.width = dimensions[:width]
        ex.height = dimensions[:height]
      end
      save_ex = true
    elsif json.include?('scripts')
      ex.scripts = json['scripts']
      ex.links = json['links']
      save_ex = true
    end

    ex.save! if save_ex

    inst_mod_sec_ex = InstModuleSectionExercise.new(
      inst_module_version: inst_module_version,
      inst_module_section: inst_module_section,
      inst_exercise: ex
    )
    inst_mod_sec_ex.points = json['points'] || 0
    inst_mod_sec_ex.required = json['required'] || false
    inst_mod_sec_ex.threshold = if json['type'] == 'pe'
                                  json['threshold'] || 1
                                elsif json['type'] == 'ae'
                                  json['threshold'] || 0
                                elsif json['type'] == 'extr'
                                  json['threshold'] || 100
                                else
                                  json['threshold'] || 5
                                end
    if json.key?('exer_options')
      inst_mod_sec_ex.options = json['exer_options'].to_json
    end
    inst_mod_sec_ex.save!
  end

  def self.handle_grade_passback(req, _res, user_id, inst_module_section_exercise_id)
    ex_progress = OdsaExerciseProgress.find_by(user_id: user_id,
                                               inst_module_section_exercise_id: inst_module_section_exercise_id)
                                               
    if req.replace_request?
      # set a new score for the user
            
      score = Float(req.score.to_s)

      if score < 0.0 || score > 1.0
        res.description = "The score must be between 0.0 and 1.0"
        res.code_major = 'failure'
      else
        # we store exercise scores in the database as an integer
        score = Integer(score * 100)
        if ex_progress.blank?
          ex_progress = OdsaExerciseProgress.new(user_id: user_id,
                inst_module_section_exercise_id: inst_module_section_exercise_id)
        end
        old_score = ex_progress.current_score
        ex_progress.update_score(score)
        ex_progress.save!

        mod_sect_ex = ex_progress.inst_module_section_exercise
        inst_module_version_id = mod_sect_ex.inst_module_version_id

        # update the score for the module containing the exercise
        mod_progress = OdsaModuleProgress.get_standalone_progress(user_id, inst_module_version_id)
        mod_progress.update_proficiency(mod_sect_ex)

        res.description = "Your old score of #{old_score} has been replaced with #{score}"
        res.code_major = 'success'
      end
    elsif req.read_request?
      # return the score for the user
      res.description = ex_progress.blank? ? "Your score is 0" : "Your score is #{ex_progress.highest_score}"
      res.score = ex_progress.blank? ? 0 : ex_progress.highest_score
      res.code_major = 'success'
    end
    
    return res
  end

  def clone(inst_module_version, inst_module_section)
    imse = InstModuleSectionExercise.new(
      inst_module_version: inst_module_version,
      inst_module_section: inst_module_section,
      inst_exercise_id: inst_exercise_id,
      points: points,
      required: required,
      threshold: threshold,
      options: options
    )
    imse.save!

    imse
  end
end
