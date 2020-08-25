module LtiOutcomes

    def self.post_score_to_consumer(score, lis_outcome_service_url, lis_result_sourcedid, consumer_key, consumer_secret)
        lti_param = {
            "lis_outcome_service_url" => lis_outcome_service_url,
            "lis_result_sourcedid" => lis_result_sourcedid,
        }

        tp = IMS::LTI::ToolProvider.new(consumer_key, consumer_secret, lti_param)
        tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider
        res = tp.post_extended_replace_result!(score: score)
        unless res.success?
            error = Error.new(:class_name => 'post_replace_result_fail',
                              :message => res.inspect,
                              :params => self.as_json.to_json)
            error.save!
        end
        return res
    end

end
