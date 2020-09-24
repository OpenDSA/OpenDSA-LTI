class GenerateCourseJob < ProgressJob::Base
  def initialize(inst_book_id, launch_url, resource_selection_url, extrtool_launch_base_url, user_id)
    @user_id = user_id
    @user = User.find_by(id: user_id)
    @inst_book = InstBook.find_by(id: inst_book_id)
    @odsa_launch_url = launch_url
    @odsa_resource_selection_url = resource_selection_url
    @extrtool_launch_base_url = extrtool_launch_base_url
    @course_offering = CourseOffering.where(:id => @inst_book.course_offering_id).first
    @term = Term.where(:id => @course_offering.term_id).first
    @course = Course.where(:id => @course_offering.course_id).first
    @organization = Organization.where(:id => @course.organization_id).first
  end

  def perform
    update_stage('Generating course in LMS')
    chapters = InstChapter.where(inst_book_id: @inst_book.id)
    update_progress_max(chapters.count + 1)
    inst_book_compile
    update_stage('Compiling OpenDSA book')
    inst_book_json = ApplicationController.new.render_to_string(
      template: "inst_books/show.json.jbuilder",
      locals: {:@inst_book => @inst_book, :@extrtool_launch_base_url => @extrtool_launch_base_url},
    )
    Rails.logger.info('inst_book_json')
    Rails.logger.info(inst_book_json)
    require 'json'
    config_file = sanitize_filename('temp_' + @user_id.to_s + '_' + Time.now.getlocal.to_s) + '.json'
    config_file_path = "public/OpenDSA/config/temp/#{config_file}"
    Rails.logger.info('config file path')
    Rails.logger.info(config_file_path)
    File.open(config_file_path, "w") do |f|
      f.write(inst_book_json)
    end

    script_path = "public/OpenDSA/tools/configure.py"
    build_path = book_path(@inst_book)
    Rails.logger.info('build_path')
    Rails.logger.info(build_path)
    require 'open3'
    command = ". /home/deploy/OpenDSA/.pyVenv/bin/activate && python3 #{script_path} #{config_file_path} -b #{build_path}"
    stdout, stderr, status = Open3.capture3(command)
    unless status.success?
      Rails.logger.info(stderr)
    end
    update_progress
  end

  def inst_book_compile
    lms_instance_id = @inst_book.course_offering.lms_instance['id']
    user_lms_access = LmsAccess.where(lms_instance_id: lms_instance_id).where(user_id: @user_id).first
    @created_LTI_tools = []
    require 'pandarus'
    client = Pandarus::Client.new(
      prefix: @inst_book.course_offering.lms_instance.url + '/api',
      token: user_lms_access.access_token,
    )
    lms_course_id = @inst_book.course_offering.lms_course_num

    canvas_course = client.get_single_course_courses(lms_course_id)
    @inst_book.course_offering.lms_course_code = canvas_course.course_code
    @inst_book.course_offering.save!
    consumer_key, consumer_secret = @user.get_lms_creds.first

    tool_data = {
      "tool_name" => "OpenDSA-LTI",
      "privacy_level" => "public",
      "consumer_key" => consumer_key,
      "consumer_secret" => consumer_secret,
      "launch_url" => @odsa_launch_url,
      "resource_selection_url" => @odsa_resource_selection_url
    }

    save_lti_app(client, lms_course_id, tool_data)

    # generate canvas course modules, items and assignments out of inst_book configurations
    save_lms_course(client, lms_course_id)
    @inst_book.last_compiled = Time.now
    @inst_book.save!
  end

  # -------------------------------------------------------------
  # Create LTI app in canvas course
  def save_lti_app(client, lms_course_id, tool_data)
    # create LTI tool in canvas if it is not defined
    tool_name = tool_data["tool_name"]
    privacy_level = tool_data["privacy_level"]
    consumer_key = tool_data["consumer_key"]
    consumer_secret = tool_data["consumer_secret"]
    launch_url = tool_data["launch_url"]
    res = client.list_external_tools_courses(lms_course_id)
    tool_exists = false
    if res
      res.each do |tool|
        tool_exists = true if tool['name'] == tool_name
      end
    end

    opts = {:url => launch_url}
    if tool_data.key?("resource_selection_url")
      opts[:resource_selection__enabled__] = true
      opts[:resource_selection__url__] = tool_data["resource_selection_url"]
      opts[:resource_selection__selection_width__] = 800
      opts[:resource_selection__selection_height__] = 600
    end

    # Add OpenDSA tools menu item in case the lti app is "OpenDSA-LTI"
    if tool_name == "OpenDSA-LTI"
      odsa_url_opts = {
        :custom_inst_book_id => @inst_book.id,
        :custom_course_offering_id => @course_offering.id
      }
      require "addressable/uri"
      uri = Addressable::URI.new
      uri.query_values = odsa_url_opts
      odsa_launch_url = launch_url + '?' + uri.query

      opts[:course_navigation__enabled__] = true
      opts[:course_navigation__text__] = "OpenDSA Tools"
      opts[:course_navigation__url__] = odsa_launch_url
      opts[:course_navigation__visibility__] = "admins"
      opts[:course_navigation__default__] = true
      opts[:custom_fields] = {
        'canvas_api_base_url': '$Canvas.api.baseUrl'
      }
    end

    if !tool_exists and !@created_LTI_tools.include? tool_name
      res = client.create_external_tool_courses(lms_course_id, tool_name,
                                                privacy_level, consumer_key, consumer_secret, opts)
      @created_LTI_tools.push(tool_name)
    end
  end

  # -------------------------------------------------------------
  # Create canvas modules that maps to OpenDSA chapters
  def save_lms_course(client, lms_course_id)
    chapters = InstChapter.where(inst_book_id: @inst_book.id).order('position')

    chapters.each do |chapter|
      opts = {:module__name__ => 'Chapter ' + chapter.position.to_s + ' ' + chapter.name,
              :module__position__ => chapter.position}

      update_stage('Generating: ' + opts[:module__name__])

      publish_chapter = false
      if !chapter.lms_chapter_id
        publish_chapter = true
        res = client.create_module(lms_course_id, chapter.name, opts)
        chapter.lms_chapter_id = res['id']
        chapter.save!
      end

      if !chapter.lms_assignment_group_id and chapter.has_gradable_sections?
        assignment_group_opts = {:name => opts[:module__name__]}
        res = client.create_assignment_group(lms_course_id, assignment_group_opts)
        chapter.lms_assignment_group_id = res['id']
        chapter.save!
      end

      save_lms_chapter(client, lms_course_id, chapter)
      # Publish the module
      if publish_chapter
        opts = {}
        opts[:module__published__] = true
        res = client.update_module(lms_course_id, chapter.lms_chapter_id, opts)
      end
      update_progress
    end
  end

  # -------------------------------------------------------------
  # For each canvas module, create text items (just a label) that maps to OpenDSA modules
  def save_lms_chapter(client, lms_course_id, chapter)
    modules = InstChapterModule.where(inst_chapter_id: chapter.id).order('module_position')

    module_item_position = 1
    modules.each do |inst_ch_module|
      title = (chapter.position.to_s || "") + "." +
              (inst_ch_module.module_position.to_s || "") + "." +
              InstModule.where(:id => inst_ch_module.inst_module_id).first.name

      save_module_as_external_tool(client, lms_course_id, chapter, inst_ch_module, module_item_position)
      module_item_position += 1
    end
  end

  # -------------------------------------------------------------
  # in canvas, module item that has external link will map OpenDSA non-gradable module
  def save_module_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                   module_item_position)
    module_name = InstModule.where(:id => inst_ch_module.inst_module_id).first.path 
    if module_name.include? '/'
      module_name = module_name.split('/')[1]  #module_name = IntroOO
    end
    title = (chapter.position.to_s.rjust(2, "0") || "") + "." +
            (inst_ch_module.module_position.to_s.rjust(2, "0") || "") + " "

    module_file_name = module_name #IntroOO
    title = title + InstModule.where(:id => inst_ch_module.inst_module_id).first.name

    odsa_url_opts = {
      :custom_inst_book_id => @inst_book.id,
      :custom_inst_chapter_module_id => (inst_ch_module.id),
      :custom_book_path => book_path(@inst_book),
      :custom_module_file_name => module_file_name,
      :custom_module_title => title,
    }
    require "addressable/uri"
    uri = Addressable::URI.new
    uri.query_values = odsa_url_opts
    launch_url = @odsa_launch_url + '?' + uri.query

    opts = {:module_item__title__ => title,
            :module_item__type__ => "ExternalTool",
            :module_item__position__ => module_item_position,
            :module_item__external_url__ => launch_url,
            :module_item__indent__ => 0}

    save_module_as_assignment(client, lms_course_id, chapter, inst_ch_module, title, opts, odsa_url_opts)
  end

  # -------------------------------------------------------------
  # If OpenDSA module is gradable, it has at least one exercise with points greater than zero.
  # in canvas, module item that refer to an assignment will map OpenDSA gradable module
  # If zeropt_assignments is true, non-gradable modules will also be map to an assignment
  def save_module_as_assignment(client, lms_course_id, chapter, chapt_module, title, opts, url_opts)
    uri = Addressable::URI.new
    uri.query_values = url_opts

    assignment_opts = {
      :assignment__submission_types__ => "external_tool",
      :assignment__external_tool_tag_attributes__ => {:url => @odsa_launch_url + '?' + uri.query},
    }

    opts[:module_item__title__] = title
    if chapt_module.gradable?
      assignment_opts[:assignment__points_possible__] = chapt_module.total_points
      # if section.soft_deadline
      #   assignment_opts[:assignment__due_at__] = section.soft_deadline.try(:strftime, "%Y-%m-%dT%H:%m:%S%:z")
      # end
      opts[:module_item__type__] = "Assignment"
      if chapt_module.lms_module_item_id && chapt_module.lms_assignment_id
        opts[:module_item__content_id__] = chapt_module.lms_assignment_id
        assignment_res = client.edit_assignment(lms_course_id, chapt_module.lms_assignment_id, assignment_opts)
        update_opts = opts
        update_opts.delete(:module_item__title__)
        update_opts.delete(:module_item__indent__)
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, chapt_module.lms_module_item_id, update_opts)
      else
        assignment_opts[:assignment__name__] = title
        assignment_opts[:assignment__assignment_group_id__] = chapter.lms_assignment_group_id
        assignment_opts[:assignment__description__] = title
        assignment_res = client.create_assignment(lms_course_id, title, assignment_opts)
        opts[:module_item__content_id__] = assignment_res['id']
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, "Assignment", assignment_res['id'], opts)
        chapt_module.lms_assignment_id = assignment_res['id']
        chapt_module.lms_module_item_id = res['id']
        chapt_module.save!
      end
    else
      if @inst_book.zeropt?
        assignment_opts[:assignment__points_possible__] = 0
        opts[:module_item__type__] = "Assignment"
        assignment_opts[:assignment__name__] = title
        assignment_opts[:assignment__assignment_group_id__] = chapter.lms_assignment_group_id
        assignment_opts[:assignment__description__] = title
        assignment_res = client.create_assignment(lms_course_id, title, assignment_opts)
        opts[:module_item__content_id__] = assignment_res['id']
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, "Assignment", assignment_res['id'], opts)
        chapt_module.lms_assignment_id = assignment_res['id']
        chapt_module.lms_module_item_id = res['id']
        chapt_module.save!
      else
        if !chapt_module.lms_module_item_id
          res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, "ExternalTool", '', opts)
          chapt_module.lms_module_item_id = res['id']
          chapt_module.save!
        end
      end
      # if section.lms_item_id
      #   res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      # else
      # if !chapt_module.lms_module_item_id
      #   res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, "ExternalTool", '', opts)
      #   chapt_module.lms_module_item_id = res['id']
      #   chapt_module.save!
      # end
    end
  end

  # -------------------------------------------------------------
  def sanitize_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '')
      .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
      .gsub(/\s+/, '_')
  end

  # -------------------------------------------------------------
  def book_path(inst_book)
    course_offering = CourseOffering.where(:id => inst_book.course_offering_id).first
    term = Term.where(:id => course_offering.term_id).first
    course = Course.where(:id => course_offering.course_id).first
    organization = Organization.where(:id => course.organization_id).first

    sanitize_filename(organization.slug) + "/" +
    sanitize_filename(course.slug) + "/" +
    sanitize_filename(term.slug) + "/" +
    sanitize_filename(course_offering.label)
  end
end
