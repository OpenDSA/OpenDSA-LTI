module ToCsv
  def to_csv(params)
    #attributes = %w{user course question_name worth_credit time_done time_taken hint_used points_earned}
    attributes = params[1]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      params[0].all.each do |attempt|
        csv << attributes.map{ |attr| attempt.send(attr) }
        #csv << attempt.attributes.map { |a,v| v }
      end
    end
  end

end