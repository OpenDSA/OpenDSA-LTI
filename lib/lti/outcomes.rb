module LtiOutcomes

    def self.post_score_to_consumer(score, lis_outcome_service_url, lis_result_sourcedid, consumer_key, consumer_secret)
        lti_param = {
            "lis_outcome_service_url" => lis_outcome_service_url,
            "lis_result_sourcedid" => lis_result_sourcedid,
        }

        tp = IMS::LTI::ToolProvider.new(consumer_key, consumer_secret, lti_param)
        tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider
        score_res = tp.post_read_result!
        if score_res.success?
            current_score = score_res.score
            Rails.logger.info("LTI score read response: #{score_res.inspect}")
            Rails.logger.info("LTI current score: #{current_score}, new score: #{score}")
            if current_score.nil? || score > current_score.to_f
                res = tp.post_extended_replace_result!(score: score)
                unless res.success?
                    error = Error.new(:class_name => 'post_replace_result_fail',
                                    :message => res.inspect,
                                    :params => {
                                        score: score,
                                        lis_outcome_service_url: lis_outcome_service_url,
                                        lis_result_sourcedid: lis_result_sourcedid
                                    }.to_json)
                    error.save!
                end
                return res
            else
                return score_res
            end
        else
            error = Error.new(:class_name => 'post_read_result_fail',
                            :message => score_res.inspect,
                            :params => {
                                score: score,
                                lis_outcome_service_url: lis_outcome_service_url,
                                lis_result_sourcedid: lis_result_sourcedid
                            }.to_json)
            error.save!
            return score_res
        end
    end
end
