module BookDataDownloadsHelper
  def to_csv(params)
    #attributes = %w{user course question_name worth_credit time_done time_taken hint_used points_earned}
    attributes = params[1]
    puts(attributes)

    CSV.generate(headers: true) do |csv|
      csv << attributes

      params[0].all.each do |attempt|
        csv << attributes.map{ |attr| attempt.send(attr) }
        #csv << attempt.attributes.map { |a,v| v }
      end
    end
  end

  def combine_attributes(records, label, array)
    unless records.first.nil?
      records.first.attributes.each do |attribute|
        array.push({attribute[0] => label});
      end
    end
    return array
  end

  def add_users(records, array)
    records.each do |record|
      puts record.user_id
      unless array.include?(record.user_id)
        array.push(record.user_id)
      end
    end
    return array
  end

  def attempt_attr_desc
    return {
        "id" => "stores students attempts for KA and PE exercises",
        "inst_book_id" => "defines OpenDSA Book configuration used by a course offering",
        "user_id" => "defines user who performed this action",
        "inst_section_id" => "defines different sections in each module",
        "inst_book_section_exercise_id" => "defines a configuration of an exercise in a section",
        "worth_credit" => "when the attempt is correct, from first time, and without using hits it worth a credit",
        "count_hints" => "number of hints used so far when the students submitted this attempt",
        "hint_used" => "whether a hint is used on this question or not",
        "points_earned" => "when this attempt is the final attmpt to got the student the proficiency, this field stores how many points the student got",
        "earned_proficiency" => "whether the student earned the proficiency when he submitted this attempt or not",
        "count_attempts" => "number of attempts so far for the current question" ,
        "ip_address" => "ip address",
        "question_name" => "the specific question name in a summary exercise",
        "request_type" => "whether this attempt is a hint object or attempt object",
        "created_at" => "event creation time",
        "updated_at" => "event update time",
        "correct" => "true if the student answer is correct",
        "pe_score" => "when the exercise is PE, this field stores the points a student should get when he correctly solve the question",
        "pe_steps_fixed" => "when the exercise is PE, this fields stores the number of steps that the student did not get correctly and the exercise fixed them for him"
    }
  end

  def progress_attr_desc
    return {
        "id" => "stores statistics about student attempts each record contains the data related to one student and one exercise",
        "inst_book_id" => "defines OpenDSA Book configuration used by a course offering",
        "user_id" => "defines user who performed this action",
        "inst_section_id" => "defines different sections in each module",
        "inst_book_section_exercise_id" => "defines a configuration of an exercise in a section",
        "current_score" => "for KA exercises, this field stores the student current points for an exercise",
        "highest_score" => "for KA exercises, this field stores the student highest number of points he could get for an exercise. The highest_score should always be bigger than or equal the current_score",
        "first_done" => "first done at",
        "last_done" => "last done at",
        "total_correct" => "the total correct attempts",
        "total_worth_credit" => "the total number of attempts that are correct, from first time, and without using hints",
        "proficient_date" => "date of proficiency",
        "current_exercise" => "this field tracks the student current question name so that when he reload the module page he will get the same question again",
        "correct_exercise" => "this field stores A list of correct exercises in order for KA framework to be able to remove them from the question pool",
        "hinted_exercise" => "this field tracks the question name on which the student used the hints. So when the student refreshes the module page he won't get credit for this question even if he solved it correctly",
        "created_at" => "event creation time",
        "updated_at" => "event update time",
        "lms_access_id" => "defines user level access to an LMS"
    }
  end

  def interaction_attr_desc
    return {
        "id" => "stores students click stream",
        "inst_book_id" => "defines OpenDSA Book configuration used by a course offering",
        "user_id" => "defines user who performed this action",
        "inst_section_id" => "defines different sections in each module",
        "inst_book_section_exercise_id" => "defines a configuration of an exercise in a section",
        "name" => "the event name (e.g. slide show step forward)",
        "description" => "the event description",
        "action_time" => "the time of which user performed the interaction",
        "uiid" => "the unique instance identifier, which allows an event to be tied to a specific load of a module page",
        "browser_family" => "browser",
        "browser_version" => "browser version",
        "os_family" => "operating system",
        "os_version" => "operating system version",
        "device" => "device",
        "ip_address" => "ip address",
        "created_at" => "event creation time",
        "updated_at" => "event update time"
    }
  end
end
