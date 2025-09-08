class LtiController < ApplicationController
  layout 'lti', only: [:launch]

  after_action :allow_iframe, only: [:launch, :resource, :launch_extrtool]
  # the consumer keys/secrets

  require 'oauth/request_proxy/action_controller_request'

  def launch

    Rails.logger.info("launch - LtiController")

    if params[:lti_message_type] == 'ContentItemSelectionRequest'
      resource()
      return
    end
    unless params.key?(:custom_inst_book_id)
      launch_standalone_resource()
      return
    end
    # must include the oauth proxy object

    @inst_book = InstBook.find_by(id: params[:custom_inst_book_id])
    @course_offering = CourseOffering.find_by(id: @inst_book.course_offering_id)
    $oauth_creds = get_oauth_creds(params[:oauth_consumer_key])

    render('error') and return unless lti_authorize!
    lms_instance = ensure_lms_instance()
    render('error') and return unless ensure_user(lms_instance)

    lti_enroll(@course_offering)

    if params.has_key?(:custom_course_offering_id)
      launch_instructor_tool()
      return
    end

    file_name = nil
    if params.key?(:custom_module_file_name)
      lms_access_id = LmsAccess.where(consumer_key: request.request_parameters['oauth_consumer_key']).pluck(:id).first
      OdsaModuleProgress.get_progress(current_user.id,
                                      params[:custom_inst_chapter_module_id],
                                      params[:custom_inst_book_id], params[:lis_outcome_service_url],
                                      params[:lis_result_sourcedid], lms_access_id)
      file_name = params[:custom_module_file_name]
    else
      file_name = params[:custom_section_file_name]
    end
    @section_html = File.read(File.join('public/OpenDSA/Books',
                                        params[:custom_book_path],
                                        '/lti_html/',
                                        "#{file_name.to_s}.html")) and return
  end

  # deprecated
  def assessment
    request_params = JSON.parse(request.body.read.to_s)
    isFullModule = request_params.key?('instChapterModuleId')

    if isFullModule
      # we check if the module score needs to be sent to the LMS whenever
      # an exercise attempt is recorded. See odsa_module_progress.rb
      render :json => {:message => 'deprecated endpoint'}.to_json
      return
    end

    hasBook = request_params.key?('instBookId')

    if hasBook
      inst_section = InstSection.find_by(id: request_params['instSectionId'])

      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_book_section_exercise_id=? AND user_id=?",
                                                          request_params['instBookSectionExerciseId'], current_user.id).select(
          "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed"
      )
      @odsa_exercise_progress = OdsaExerciseProgress.where("inst_book_section_exercise_id=? AND user_id=?",
                                                           request_params['instBookSectionExerciseId'], current_user.id).select("user_id, current_score, highest_score,
                                  total_correct, proficient_date,first_done, last_done")
    else
      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_course_offering_exercise_id=? AND user_id=?",
                                                          request_params['instCourseOfferingExerciseId'], current_user.id).select(
          "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed"
      )
      @odsa_exercise_progress = OdsaExerciseProgress.where("inst_course_offering_exercise_id=? AND user_id=?",
                                                           request_params['instCourseOfferingExerciseId'], current_user.id).select("user_id, current_score, highest_score,
                                  total_correct, proficient_date,first_done, last_done")
    end

    a = @odsa_exercise_attempts
    b = @odsa_exercise_progress
    TableHelper.arg(a, b)
    f = render_to_string "lti/table.html.erb"

    launch_params = request_params['toParams']['launch_params']
    if launch_params
      key = launch_params['oauth_consumer_key']
      $oauth_creds = get_oauth_creds(key)
    else
      @message = "The tool never launched"
      render(:error)
    end

    lti_param = {
        "lis_outcome_service_url" => "#{launch_params['lis_outcome_service_url']}",
        "lis_result_sourcedid" => "#{CGI.unescapeHTML(launch_params['lis_result_sourcedid'] || '')}",
    }

    # @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], launch_params)
    @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], lti_param)
    # add extension
    @tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider

    if !@tp.outcome_service?
      @message = "This tool wasn't lunched as an outcome service"
      render(:error)
    end

    # post the given score to the TC
    score = (request_params['toParams']['score'] != '' ? request_params['toParams']['score'] : nil)
    #res = @tp.post_replace_exercise_progressresult!(score)
    res = @tp.post_extended_replace_result!(score: score, text: f)

    if res.success?
      if hasBook
        inst_section.lms_posted = true
        inst_section.time_posted = Time.now
        inst_section.save!
      end
      render :json => {:message => 'success', :res => res.as_json}.to_json
    else
      if hasBook
        inst_section.lms_posted = false
        inst_section.save!
      end
      render :json => {:message => 'failure', :res => res.as_json}.to_json, :status => :bad_request
      error = Error.new(:class_name => 'post_replace_result_fail',
                        :message => res.inspect, :params => request_params.to_s)
      error.save!
    end
  end

  def xml_config

    Rails.logger.info("xml_config - LtiController")
    Rails.logger.info(request)
    Rails.logger.info(params)

    host = request.scheme + "://" + request.host_with_port
    launch_url = host + '/lti/launch'
    tc = IMS::LTI::ToolConfig.new(:title => "OpenDSA", :launch_url => launch_url)
    tc.extend IMS::LTI::Extensions::Canvas::ToolConfig
    tc.description = "OpenDSA LTI Tool Provider supporting grade pass-back."
    tc.canvas_privacy_public!
    # tc.canvas_resource_selection!({
    #   :url => host + '/lti/resource',
    #   :selection_width => 800,
    #   :selection_height => 600,
    # })
    tc.set_ext_params('canvas.instructure.com', {
        'assignment_selection': {
            'message_type': 'ContentItemSelectionRequest',
            'url': launch_url,
            'selection_width': 800,
            'selection_height': 600
        },
        'link_selection': {
            'message_type': 'ContentItemSelectionRequest',
            'url': launch_url,
            'selection_width': 800,
            'selection_height': 600
        },
        'editor_button': {
            'message_type': 'ContentItemSelectionRequest',
            'url': launch_url,
            'selection_width': 800,
            'selection_height': 600
        },
        'icon_url': "#{request.protocol}#{request.host_with_port}/opendsa_logo50.png",
        'custom_fields': {
            'custom_canvas_course_id': '$Canvas.course.id',
            'custom_contact_email_primary': '$Person.email.primary',
        },
        # 'selection_height': 800,
        # 'selection_width': 600
    })

    render xml: tc.to_xml(:indent => 2), :content_type => 'text/xml'
  end

  def resource
    # must include the oauth proxy object

    $oauth_creds = get_oauth_creds(params[:oauth_consumer_key])
    if $oauth_creds.blank?
      @message = 'Please make sure the consumer key is set correctly in the OpenDSA tool configuration in the LMS.'
      render 'error'
      return
    end

    render('error') and return unless lti_authorize!

    lms_type = ensure_lms_type(params[:tool_consumer_info_product_family_code])
    if lms_type.blank?
      @message = 'OpenDSA requires that the request include the "tool_consumer_info_product_family_code" parameter'
      render 'error'
      return
    end

    lms_instance = ensure_lms_instance()

    email = params.key?(:lis_person_contact_email_primary) ?
                params[:lis_person_contact_email_primary] :
                params[:oauth_consumer_key]

    if !ensure_user(lms_instance) || !(@tp.context_instructor? || current_user.global_role.is_instructor_or_admin_or_researcher?)
      @message = 'OpenDSA: You must be an instructor to perform this action.'
      render 'error'
      return
    end

    @deep_linking = params[:lti_message_type] == 'ContentItemSelectionRequest'
    @hide_gradebook_settings = !(params[:auto_create] == true || lms_type.name.downcase == 'blackboardlearn')
    @lms_course_num = get_lms_course_num(lms_type.name, lms_instance)
    @lms_course_code = "#{params[:context_title]} - #{params[:context_label]}"
    @lms_instance_id = lms_instance.id
    @organization_id = lms_instance.organization_id
    @course_offering = CourseOffering.find_by(
        lms_instance_id: lms_instance.id,
        lms_course_num: @lms_course_num,
        )
    if @course_offering.blank?
      if lms_instance.organization_id.blank?
        @organizations = Organization.all.order(:name)
      end
      @terms = Term.on_or_future.order(:starts_on)
    end

    @launch_url = request.protocol + request.host_with_port + "/lti/launch"
    module_info = InstModule.get_current_versions_dict()
    @json = module_info.to_json()

    render 'resource', layout: 'lti_resource'
  end

  def content_item_selection
    if !user_signed_in? #|| !current_user.global_role.is_instructor_or_admin_or_researcher?
      render :json => {:status => 'fail', :message => 'OpenDSA: Please ensure third-party cookies are enabled in you browser\'s settings.'}.to_json,
             :status => :unauthorized
      return
    end

    consumer_key = params['oauth_consumer_key']
    $oauth_creds = get_oauth_creds(consumer_key)
    consumer_secret = $oauth_creds[consumer_key]
    return_url = params[:content_item_return_url]

    course_offering = CourseOffering.find(params[:course_offering_id])
    unless course_offering.is_instructor?(current_user)
      render :json => {:status => 'fail', :message => 'You must be an instructor for the course offering.'}.to_json,
             :status => :unauthorized
      return
    end

    resourceInfo = nil
    resourceUrlId = nil
    launchUrl = request.protocol + request.host_with_port + "/lti/launch"
    require "addressable/uri"
    if params['selected'].key?('moduleInfo')
      resourceInfo = {
          points: params['selected']['moduleSettings']['points'],
          resource_id: params['selected']['moduleInfo']['id'],
          title: params['selected']['moduleInfo']['name'],
      }

      resourceUrlId = "#{request.protocol}#{request.host_with_port}/inst_modules/#{resourceInfo[:resource_id]}"

      uri = Addressable::URI.new
      uri.query_values = {custom_inst_module_id: resourceInfo[:resource_id]}
      launchUrl = launchUrl + '?' + uri.query
    else
      exinfo = params['selected']['exerciseInfo']
      exSettings = params['selected']['exerciseSettings']
      resourceInfo = {
          points: exSettings['points'] || 1,
          resource_id: exinfo['id'],
          title: exinfo["name"]
      }
      resourceUrlId = "#{request.protocol}#{request.host_with_port}/inst_exercise/#{exinfo['id']}"
      uri = Addressable::URI.new
      uri.query_values = {
          custom_ex_short_name: exinfo['short_name'],
          custom_ex_settings: exSettings.to_json
      }
      launchUrl = launchUrl + '?' + uri.query
    end

    isGradable = params['selected']['isGradable']
    logoUrl = "#{request.protocol}#{request.host_with_port}/opendsa_logo50.png"

    if return_url.blank?
      # Canvas resource selection
      render :json => {launchUrl: launchUrl}, :status => :ok
      return
    end

    content_item_params = {}
    content_item_params["lti_message_type"] = 'ContentItemSelection'
    content_item_params["lti_version"] = "LTI-1p0"
    unless params["data"].blank?
      content_item_params["data"] = params["data"]
    end
    content_item = {
        "@type": "LtiLinkItem",
        "mediaType": "application/vnd.ims.lti.v1.ltilink",
        "icon": {
            "@id": logoUrl,
            "width": 50,
            "height": 50
        },
        "title": "OpenDSA: " + resourceInfo[:title],
        "placementAdvice": {
            "displayWidth": 950,
            "displayHeight": params['selected'].key?('moduleInfo') ? 1000 : 750,
            "presentationDocumentTarget": "iframe"
        },
        'url': launchUrl,
        # "custom": {
        # }
    }
    if isGradable
      content_item["lineItem"] = {
          "@type": "LineItem",
          "label": "OpenDSA: " + resourceInfo[:title],
          "reportingMethod": "res:totalScore",
          "assignedActivity": {
              "@id": "#{resourceUrlId}",
              "activityId": "#{resourceInfo[:resource_id]}"
          },
          "scoreConstraints": {
              "@type": "NumericLimits",
              "normalMaximum": resourceInfo[:points].to_f,
              "extraCreditMaximum": 0,
              "totalMaximum": resourceInfo[:points].to_f
          }
      }
    end
    content_items = {
        "@context": "http://purl.imsglobal.org/ctx/lti/v1/ContentItem",
        "@graph": [
            content_item
        ]
    }
    content_item_params["content_items"] = content_items.to_json

    require 'lti/oauth'
    oauth_info = OAuth.generate_oauth_params(consumer_key, consumer_secret, return_url,
                                             content_item_params)

    render :json => oauth_info.as_json, :status => :ok
  end

  def launch_extrtool
    if current_user.blank?
      @message = "Error: current user could not be identified"
      render :error
      return
    end

    workout_id = request.query_parameters['workoutId']
    launch_extrtool_helper(params[:exercise_id], params[:context_type], workout_id)
  end

  def grade_passback
    req = IMS::LTI::OutcomeRequest.from_post_request(request)
    res = IMS::LTI::OutcomeResponse.new
    res.message_ref_identifier = req.message_identifier
    res.operation = req.operation
    res.severity = 'status'

    # lis_result_sourcedid was sent by us in the original LTI launch request
    # and identifies the user and exercise the score is for
    if req.lis_result_sourcedid.blank?
      res.description = "Missing lis_result_sourcedid"
      res.code_major = 'failure'
      return
    end

    tokens = req.lis_result_sourcedid.split("_")
    user_id = tokens[0]
    exercise_id = tokens[1]

    if req.replace_request? || req.read_request?
      if tokens.size == 3
        context_type = tokens[2]
        if context_type == 'standalone-module'
          res = InstModuleSectionExercise.handle_grade_passback(req, res, user_id, exercise_id)
        elsif context_type == 'standalone-exercise'
          res = InstCourseOfferingExercise.handle_grade_passback(req, res, user_id, exercise_id)
        else
          res.description = "invalid lis_result_sourcedid"
          res.code_major = 'failure'
          return
        end
      else
        res = InstBookSectionExercise.handle_grade_passback(req, res, user_id, exercise_id)
      end
    elsif req.delete_request?
      res.code_major = 'unsupported'
      res.description = "#{req.operation} is not supported"
    else
      res.severity = 'error'
      res.code_major = 'unsupported'
      res.description = "#{req.operation} is not supported"
    end

    xml = res.generate_response_xml
    render xml: xml
  end

  private

  def launch_extrtool_helper(exercise_id, context_type = nil, workout_id)
    exercise = nil
    course_offering = nil
    lis_result_sourcedid = nil
    resource_link_id = nil

    if context_type.blank?
      exercise = InstBookSectionExercise.includes(:inst_exercise, :inst_book, inst_book: [{course_offering: [:term, :course]}])
                     .find_by(id: exercise_id)
      course_offering = exercise.inst_book.course_offering
      lis_result_sourcedid = "#{current_user.id}_#{exercise.id}"
      resource_link_id = "#{exercise.id}"
    elsif context_type == 'standalone-module'
      exercise = InstModuleSectionExercise.includes(:inst_exercise, inst_module_version: [{course_offering: [:term, :course]}])
                     .find(exercise_id)
      course_offering = exercise.inst_module_version.course_offering
      lis_result_sourcedid = "#{current_user.id}_#{exercise.id}_#{context_type}"
      resource_link_id = "#{exercise.id}_#{context_type}"
    elsif context_type == 'standalone-exercise'
      exercise = InstCourseOfferingExercise.includes(:inst_exercise, course_offering: [:term, :course])
                     .find(exercise_id)
      course_offering = exercise.course_offering
      lis_result_sourcedid = "#{current_user.id}_#{exercise.id}_#{context_type}"
      resource_link_id = "#{exercise.id}_#{context_type}"
    else
      @message = "Error: unrecognized value '#{context_type}' for parameter 'context_type'"
      render :error
      return
    end

    if exercise.blank?
      @message = "Error: could not locate exercise with id '#{exercise_id}'"
      unless context_type.blank?
        @message += " and context type '#{context_type}'"
      end
      render :error
      return
    end

    unless course_offering.is_enrolled?(current_user)
      @message = 'Error: you are not enrolled in this course'
      render :error
      return
    end

    tool = LearningTool.find_by(name: exercise.inst_exercise.learning_tool)
    host = request.scheme + "://" + request.host_with_port

    @launch_url = tool.launch_url
    launch_params = {}
    launch_params["launch_url"] = @launch_url
    launch_params["context_label"] = course_offering.course.number
    launch_params["context_title"] = course_offering.course.name
    launch_params["context_id"] = "#{course_offering.id}"
    launch_params["lis_outcome_service_url"] = "#{host}#{lti_grade_passback_path}"
    # we don't need/want scores for instructors
    unless course_offering.is_instructor?(current_user)
      launch_params["lis_result_sourcedid"] = lis_result_sourcedid
    end
    launch_params["lti_message_type"] = "basic-lti-launch-request"
    launch_params["lti_version"] = "LTI-1p0"
    launch_params["resource_link_id"] = resource_link_id
    launch_params["resource_link_title"] = exercise.inst_exercise.short_name
    launch_params["tool_consumer_info_product_family_code"] = "opendsa"
    launch_params["user_id"] = "#{current_user.id}"
    launch_params["lis_person_name_given"] = current_user.first_name
    launch_params["lis_person_name_family"] = current_user.last_name
    launch_params["lis_person_contact_email_primary"] = current_user.email
    launch_params["ext_lti_assignment_id"] = resource_link_id
    launch_params["roles"] = get_user_course_role(course_offering)
    launch_params["launch_presentation_document_target"] = "iframe"
    launch_params["custom_course_name"] = course_offering.course.name
    launch_params["custom_course_number"] = course_offering.course.number
    launch_params["custom_label"] = course_offering.label
    launch_params["custom_term"] = course_offering.term.slug
    if workout_id
      launch_params["custom_gym_workout_id"] = workout_id
    end

    @tc = IMS::LTI::ToolConsumer.new(tool.key, tool.secret, launch_params)
    @launch_data = @tc.generate_launch_data()

    render 'launch_extrtool', layout: 'header_minimal'
  end

  def get_user_course_role(course_offering)
    if course_offering.is_instructor?(current_user)
      return "Instructor"
    else
      return "Learner"
    end
  end

  def launch_standalone_resource

    $oauth_creds = get_oauth_creds(params[:oauth_consumer_key])
    lms_instance = ensure_lms_instance()
    lms_type_name = params[:tool_consumer_info_product_family_code].downcase
    lms_course_num = get_lms_course_num(lms_type_name, lms_instance)
    course_offering = CourseOffering.where(lms_course_num: lms_course_num,
                                           lms_instance_id: lms_instance.id).first

    render('error') and return unless lti_authorize!
    render('error') and return unless ensure_user(lms_instance)

    if course_offering.blank?
      unless @tp.context_instructor?
        @message = 'OpenDSA: An instructor must access this exercise first.'
        render 'error'
        return
      end
      term = Term.find_term(params[:custom_term])
      orgid = lms_instance.organization_id
      if orgid.blank?
        @message = 'OpenDSA: Could not determine tool consumer organization.'
        render 'error'
        return
      end
      coursenum = nil
      if params.key?(:custom_course_number)
        course = Course.find_by(organization_id: orgid, number: params[:custom_course_number])
      elsif params.key?(:custom_course_name)
        course = Course.find_by(organization_id: orgid, name: params[:custom_course_name])
      else
        course = Course.find_by(organization_id: orgid, number: params[:context_label])
        if course.blank?
          course = Course.new(name: params[:context_title],
                              number: params[:context_label],
                              organization_id: orgid,
                              user_id: current_user.id)
          course.save!
        end
      end
      course_offering = CourseOffering.new(
          course: course,
          term: term,
          label: params[:custom_label] || "#{params[:context_title]} - #{params[:context_label]}",
          lms_instance: lms_instance,
          lms_course_code: "#{params[:context_title]} - #{params[:context_label]}",
          lms_course_num: lms_course_num,
          )
      course_offering.save!
    end

    lti_enroll(course_offering)

    if params.key?(:custom_inst_module_id)
      launch_standalone_module(course_offering, lms_instance)
    else
      launch_standalone_exercise(course_offering, lms_instance)
    end
  end

  def launch_standalone_exercise(course_offering, lms_instance)

    if params.key?(:custom_inst_course_offering_exercise_id)
      # TODO: ensure that the exercise instance belongs to the course offering
      @course_off_ex = InstCourseOfferingExercise.find_and_update(params[:custom_inst_course_offering_exercise_id],
                                                                  params[:resource_link_id], params[:resource_link_title])
      @ex = @course_off_ex.inst_exercise
    elsif params.key?(:custom_ex_short_name)
      ex_settings = nil
      if params.key?(:custom_ex_settings)
        ex_settings = JSON.parse(params[:custom_ex_settings])
      end
      @ex = InstExercise.find_by(short_name: params[:custom_ex_short_name])
      @course_off_ex = InstCourseOfferingExercise.find_or_create_resource(course_offering.id,
                                                                          params[:resource_link_id], params[:resource_link_title], @ex, ex_settings)
    else
      # Used for older exercises created before workflow was updated. Can likely be removed after a while.
      @ex = InstExercise.find_by(short_name: params[:ex_short_name])
      @course_off_ex = InstCourseOfferingExercise.find_or_create_resource(course_offering.id,
                                                                          params[:resource_link_id], params[:resource_link_title], @ex, nil)
    end

    if lms_instance.has_oauth_creds?()
      lms_access_id = nil
    else
      lms_access_id = LmsAccess.find_by(consumer_key: params[:oauth_consumer_key]).id
    end

    OdsaExerciseProgress.get_courseoffex_progress(current_user.id,
                                                  @course_off_ex.id,
                                                  params[:lis_outcome_service_url],
                                                  params[:lis_result_sourcedid],
                                                  lms_access_id)

    if !@ex.av_address.blank?
      @av_address = @course_off_ex.build_av_address(@ex.av_address)
      render "launch_avembed", layout: 'lti_launch'
    elsif !@ex.learning_tool.blank?
      launch_extrtool_helper(@course_off_ex.id, 'standalone-exercise')
    else
      render 'launch_inlineav', layout: 'lti_launch'
    end
  end

  def launch_standalone_module(course_offering, lms_instance)
    # check for existing module
    @mod_version = InstModuleVersion.find_by(resource_link_id: params[:resource_link_id], course_offering_id: course_offering.id)
    # clone template module if necessary
    if @mod_version.blank?
      instmod = InstModule.find(params[:custom_inst_module_id])
      current_template = instmod.current_version
      @mod_version = current_template.clone(course_offering, params[:resource_link_id], params[:resource_link_title])
    end

    # build dictionary of exercise settings
    exercise_objs = @mod_version.inst_module_section_exercises.includes(:inst_exercise)
    @exercises = {}
    exercise_objs.each do |obj|
      ex_data = {
          'inst_module_section_exercise_id' => obj.id,
          'inst_module_version_id' => obj.inst_module_version_id,
          'inst_module_section_id' => obj.inst_module_section_id,
          'points' => obj.points,
          'threshold' => obj.threshold,
          'required' => obj.required,
          'options' => obj.options,
          'short_name' => obj.inst_exercise.short_name,
          'long_name' => obj.inst_exercise.name,
          'type' => obj.inst_exercise.ex_type,
          'learning_tool' => obj.inst_exercise.learning_tool,
      }
      unless ex_data['learning_tool'].blank?
        extrtool_launch_base_url = request.protocol + request.host_with_port + "/lti/launch_extrtool"
        ex_data['launch_url'] = "#{extrtool_launch_base_url}/#{obj.id}?context_type=standalone-module"
      end
      @exercises[ex_data['short_name']] = ex_data
    end

    if lms_instance.has_oauth_creds?()
      lms_access_id = nil
    else
      lms_access_id = LmsAccess.find_by(consumer_key: params[:oauth_consumer_key]).id
    end

    # ensure module progress exists and update it if necessary
    mod_prog = OdsaModuleProgress.get_standalone_progress(current_user.id,
                                                          @mod_version.id, params[:lis_outcome_service_url],
                                                          params[:lis_result_sourcedid], lms_access_id)

    @section_html = File.read(@mod_version.file_path) and return
  end

  def launch_instructor_tool
    if !user_signed_in? || !@course_offering.is_instructor?(current_user)
      @message = 'You must be signed in as an instructor for this course offering.'
      render 'error'
      return
    end

    @course_enrollment = CourseEnrollment.where("course_offering_id=?", @course_offering.id)
    @student_list = []
    @course_enrollment.each do |s|
      q = User.where("id=?", s.user_id).select("id, first_name, last_name").first
      @student_list.push(q)
      @student_list = @student_list.sort_by &:first_name
    end

    @course_id = @course_offering.id
    @instBook = @course_offering.odsa_books.first

    @chapter_list = InstChapter.includes(inst_chapter_modules: [:inst_module]).where("inst_book_id = ? AND inst_chapter_modules.lms_assignment_id IS NOT NULL", @instBook.id).references(:inst_chapter_modules)
    @is_admin = current_user.global_role.is_admin?

    render 'odsa_tools.html.haml' and return
  end

  def ensure_lms_type(type_name)
    if type_name.blank?
      type_name = 'canvas'
    end
    type_name.downcase!
    lms_type = LmsType.find_by('lower(name) = :name', name: type_name)
    if lms_type.blank?
      lms_type = LmsType.new(name: type_name)
      lms_type.save!
    end
    return lms_type
  end

  def lti_enroll(course_offering)
    role = @tp.context_instructor? ? CourseRole.instructor : CourseRole.student
    if course_offering &&
        course_offering.can_enroll? &&
        !course_offering.is_enrolled?(current_user)
      CourseEnrollment.create(
          course_offering: course_offering,
          user: current_user,
          course_role: role,
          )
    elsif course_offering.is_enrolled?(current_user)
      # check if the user's course role has changed
      ce = CourseEnrollment.find_by(course_offering_id: course_offering.id,
                                    user_id: current_user.id)
      if ce.course_role != role
        # update user's course role
        ce.course_role = role
        ce.save!
      end
    end
  end

  def ensure_lms_instance()
    uri = URI.parse(request.referrer)
    url = uri.scheme + '://' + uri.host
    lms_instance = LmsInstance.find_by(url: url)
    if lms_instance.blank?
      lms_instance = LmsInstance.new(
          url: url,
          lms_type: LmsType.find_by('lower(name) = :name', name: params[:tool_consumer_info_product_family_code].downcase),
          )
      lms_instance.save
    end
    return lms_instance
  end

  def ensure_user(lms_instance)
    email = params[:lis_person_contact_email_primary] || params[:custom_contact_email_primary]
    if email.blank?
      # try to uniquely identify user some other way
      if params[:user_id].blank?
        @message = 'OpenDSA: Unable to uniquely identify user'
        return false
      end
      email = "#{lms_instance.id}_#{params[:user_id]}@#{lms_instance.url}"
    end
    @user = User.where(email: email).first

    if @user.blank?
      # TODO: should mark this as LMS user then prevent this user from login to opendsa domain
      @user = User.new(:email => email,
                       :password => email,
                       :password_confirmation => email,
                       :first_name => params[:lis_person_name_given],
                       :last_name => params[:lis_person_name_family])
      unless @user.save
        @message = "OpenDSA: Failed to create user"
        error = Error.new(:class_name => 'user_create_fail',
                          :message => "Failed to create user #{email}", :params => params.to_s)
        error.save!
        return false
      end
    elsif @user.first_name != params[:lis_person_name_given] || @user.last_name != params[:lis_person_name_family]
      # update user's name
      @user.first_name = params[:lis_person_name_given]
      @user.last_name = params[:lis_person_name_family]
      @user.save
    end
    successful = sign_in @user
    unless successful
      @message = 'OpenDSA: sign-in failed'
      error = Error.new(:class_name => 'user_sign_in_fail',
                        :message => "Failed to sign in user #{email}", :params => params.to_s)
      error.save!
      return false
    end
    return true #successful
  end

  def lti_authorize!
    Rails.logger.info("lti_authorize! - LtiController")

    if $oauth_creds.blank?
      @message = "OpenDSA: No OAuth credentials found"
      return false
    elsif key = params['oauth_consumer_key']
      if secret = $oauth_creds[key]

        @tp = IMS::LTI::ToolProvider.new(key, secret, params)

        lms_type_name = params.key?(:tool_consumer_info_product_family_code) ?
                params[:tool_consumer_info_product_family_code].downcase : 'other'

        if lms_type_name.downcase == 'canvas'
          require 'lti/message_authenticator'

          launch_path = request.url.split("?")[0]
          authenticator = IMS::LTI::MessageAuthenticator.new(launch_path, request.request_parameters, secret)

          Rails.logger.info("lti_authorize: lms_type_name: #{lms_type_name} - authenticator.valid_signature?")
          if !authenticator.valid_signature?
            @message = "OpenDSA: The OAuth signature was invalid"
            Rails.logger.info("lti_authorize: lms_type_name: #{lms_type_name} - OAuth signature: Invalid")
            return false
          end
          Rails.logger.info("lti_authorize: OAuth signature: Valid")
        else
          Rails.logger.info("lti_authorize: lms_type_name: #{lms_type_name} - @tp.valid_request?")
          if !@tp.valid_request?(request)
            @message = "OpenDSA: The OAuth signature was invalid"
            Rails.logger.info("lti_authorize: lms_type_name: #{lms_type_name} - OAuth signature: Invalid")
            return false
          end
          Rails.logger.info("lti_authorize: lms_type_name: #{lms_type_name} - OAuth signature: Valid")
        end

        # check if `params['oauth_nonce']` has already been used
        # Need to be implemented

        #check if the message is too old
        if DateTime.strptime(request.request_parameters['oauth_timestamp'],'%s') < 1440.minutes.ago
          @message = "OpenDSA: Your request is too old."
          return false
        end

        return true
      else
        @message = "OpenDSA: Consumer key wasn't recognized"
        @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
        @tp.lti_msg = "Your consumer didn't use a recognized key."
        @tp.lti_errorlog = "You did it wrong!"
        @message = "OpenDSA: Consumer key wasn't recognized"

        return false
      end
    else
      @message = "OpenDSA: No consumer key"
      return false
    end

  end

  def get_lms_course_num(lms_type_name, lms_instance)
    if params.key?(:custom_canvas_course_id)
      return params[:custom_canvas_course_id]
    else
      # generate a unique string to use as the course id
      return "#{lms_type_name}_#{lms_instance.id}_#{params[:context_id]}"
    end
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def was_nonce_used_in_last_x_minutes?(nonce, minutes = 60)
    # some kind of caching solution or something to keep a short-term memory of used nonces
    false
  end

  def get_oauth_creds(key)
    oauth_creds = LmsInstance.get_oauth_creds(key)
    if oauth_creds.blank?
      oauth_creds = LmsAccess.get_oauth_creds(key)
    end
    return oauth_creds
  end
end
