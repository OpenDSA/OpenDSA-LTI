class GenerateCourseJob < ProgressJob::Base
  def initialize(inst_book_id, launch_url, user_id)
    @user_id = user_id
    @inst_book = InstBook.find_by(id: inst_book_id)
    @odsa_launch_url = launch_url
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
      template: 'inst_books/show.json.jbuilder',
      locals: {:@inst_book => @inst_book})

    require 'json'
    config_file = sanitize_filename('temp_' + @user_id.to_s + '_' + Time.now.getlocal.to_s) + '.json'
    config_file_path = "public/OpenDSA/config/temp/#{config_file}"
    File.open(config_file_path,"w") do |f|
      f.write(inst_book_json)
    end

    script_path = "public/OpenDSA/tools/configure.py"
    build_path = book_path(@inst_book)
    value = %x(python #{script_path} #{config_file_path} -b #{build_path})
    update_progress
  end

  def inst_book_compile
    lms_instance_id = @inst_book.course_offering.lms_instance['id']
    user_lms_access = LmsAccess.where(lms_instance_id: lms_instance_id).where(user_id: @user_id).first
    @created_LTI_tools = []
    require 'pandarus'
    client = Pandarus::Client.new(
      prefix: @inst_book.course_offering.lms_instance.url + '/api',
      token: user_lms_access.access_token)
    lms_course_id = @inst_book.course_offering.lms_course_num

    tool_data ={
      "tool_name" => "OpenDSA-LTI",
      "privacy_level" => "public",
      "consumer_key" => @inst_book.course_offering.lms_instance['consumer_key'],
      "consumer_secret" => @inst_book.course_offering.lms_instance['consumer_secret'],
      "launch_url" => @odsa_launch_url
    }

    save_lti_app(client, lms_course_id, tool_data)

    # generate canvas course modules, items and assignments out of inst_book configurations
    save_lms_course(client, lms_course_id)
    @inst_book.last_compiled = Time.now
    @inst_book.save
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
      opts = {:module__name__ => 'Chapter '+ chapter.position.to_s + ' ' + chapter.name,
              :module__position__ => chapter.position}

      update_stage('Generating: ' + opts[:module__name__])

      if !chapter.lms_chapter_id
        res = client.create_module(lms_course_id, chapter.name, opts)
        chapter.lms_chapter_id = res['id']
        chapter.save
      end

     assignment_group_opts = {:name => 'Chapter '+ chapter.position.to_s + ' ' + chapter.name}

      if !chapter.lms_assignment_group_id and chapter.has_gradable_sections?
        res = client.create_assignment_group(lms_course_id, assignment_group_opts)
        chapter.lms_assignment_group_id = res['id']
        chapter.save
      end

      save_lms_chapter(client, lms_course_id, chapter)
      # Publish the module and its all sections
      opts[:module__published__] = true
      res = client.update_module(lms_course_id, chapter.lms_chapter_id, opts)

      update_progress
    end
  end

  # -------------------------------------------------------------
  # For each canvas module, create text items (just a label) that maps to OpenDSA modules
  def save_lms_chapter(client, lms_course_id, chapter)

    modules = InstChapterModule.where(inst_chapter_id: chapter.id).order('module_position')

    module_item_position = 1
    modules.each do |inst_ch_module|
      title = (chapter.position.to_s||"")+"."+
                 (inst_ch_module.module_position.to_s||"")+"."+
                 InstModule.where(:id => inst_ch_module.inst_module_id).first.name
      opts = {:module_item__title__ => title,
                    :module_item__type__ => 'SubHeader',
                    :module_item__position__ => module_item_position}

      if inst_ch_module.lms_module_item_id
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, inst_ch_module.lms_module_item_id, opts)
      else
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'SubHeader', '', opts)
        inst_ch_module.lms_module_item_id = res['id']
        inst_ch_module.save
      end

      module_item_position = save_lms_section(client, lms_course_id, chapter, inst_ch_module, module_item_position)
      module_item_position += 1
    end
  end

  # -------------------------------------------------------------
  # Under each text item in canvas create external links the maps to OpenDSA sections
  # Section can be non-gradable as:
  # 1- OpenDSA module that doesn't contain any sections, the entire module will be considered as one non-gradable section
  # 2- section contains one or more exercsies which all of them have 0 points
  # in canvas, module item that has external link will map OpenDSA non-gradable section
  def save_lms_section(client, lms_course_id, chapter, inst_ch_module, module_item_position)

    sections = InstSection.where(inst_chapter_module_id: inst_ch_module.id)


    section_item_position = 1
    section_file_name_seq = 1

    if !sections.empty?
      sections.each do |section|
        save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                      section, module_item_position, section_item_position, section_file_name_seq)
        section_item_position += 1
        learning_tool = nil
        learning_tool = section.learning_tool
        if !learning_tool
          section_file_name_seq += 1
        end
      end
    else
      save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                    nil, module_item_position, section_item_position, section_file_name_seq)
    end

    module_item_position + section_item_position

  end

  # -------------------------------------------------------------
  # in canvas, module item that has external link will map OpenDSA non-gradable section
  def save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                    section, module_item_position, section_item_position, section_file_name_seq)

    module_name = InstModule.where(:id => inst_ch_module.inst_module_id).first.path
    if module_name.include? '/'
      module_name = module_name.split('/')[1]
    end

    title = (chapter.position.to_s.rjust(2, "0")||"") + "." +
            (inst_ch_module.module_position.to_s.rjust(2, "0")||"") + "." +
            section_item_position.to_s.rjust(2, "0") + " - "

    learning_tool = nil
    if section
      section_file_name = module_name + "-" + section_file_name_seq.to_s.rjust(2, "0")
      title = title + section.name

      learning_tool = section.learning_tool
      if learning_tool
        learning_tool_obj = LearningTool.where(:name => learning_tool).first
        launch_url = learning_tool_obj.launch_url
        tool_data ={
          "tool_name" => learning_tool_obj['name'],
          "privacy_level" => "public",
          "consumer_key" => learning_tool_obj['key'],
          "consumer_secret" => learning_tool_obj['secret'],
          "launch_url" => launch_url
        }
        save_lti_app(client, lms_course_id, tool_data)

        learning_tool_url_opts = {
          :custom_term => @term.slug,
          :custom_label => @course_offering.label,
          :custom_course_number => @course.number,
          :custom_course_name => @course.name
        }

        require "addressable/uri"
        uri = Addressable::URI.new
        uri.query_values = learning_tool_url_opts
        launch_url = launch_url + '?' + uri.query

      end
    else
      section_file_name = module_name
      title = title + InstModule.where(:id => inst_ch_module.inst_module_id).first.name
    end

    if !learning_tool
      odsa_url_opts = {
        :custom_inst_book_id => @inst_book.id,
        :custom_inst_section_id => (section.id if section),
        :custom_book_path => book_path(@inst_book),
        :custom_section_file_name => section_file_name,
        :custom_section_title => title
      }

      require "addressable/uri"
      uri = Addressable::URI.new
      uri.query_values = odsa_url_opts
      launch_url = @odsa_launch_url + '?' + uri.query
    end

    opts = {:module_item__title__ => title,
            :module_item__type__ => 'ExternalTool',
            :module_item__position__ => module_item_position + section_item_position,
            :module_item__external_url__ => launch_url,
            :module_item__indent__ => 1
            }

    if learning_tool
      save_learning_tool(client, lms_course_id, chapter, section, title, opts)
    else
      if section
        save_section_as_assignment(client, lms_course_id, chapter, section, title, opts, odsa_url_opts)
      else
        if inst_ch_module.lms_section_item_id
          res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, inst_ch_module.lms_section_item_id, opts)
        else
          res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'ExternalTool', '', opts)
          inst_ch_module.lms_section_item_id = res['id']
          inst_ch_module.save
        end
      end
    end

  end

  def save_learning_tool(client, lms_course_id, chapter, section, title, opts)

    assignment_opts = {
      :assignment__name__ => title,
      :assignment__submission_types__ => "external_tool",
      :assignment__external_tool_tag_attributes__ => {:url => opts[:module_item__external_url__] },
      :assignment__assignment_group_id__ => chapter.lms_assignment_group_id,
      :assignment__description__ => title
    }

    if section.gradable
      assignment_opts[:assignment__points_possible__] = InstBookSectionExercise.where("inst_section_id = ? AND points > 0", section.id).first.points
      opts[:module_item__type__] = 'Assignment'
      if section.lms_item_id && section.lms_assignment_id
        opts[:module_item__content_id__] = section.lms_assignment_id
        assignment_res = client.edit_assignment(lms_course_id, section.lms_assignment_id, assignment_opts )
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      else
        assignment_res = client.create_assignment(lms_course_id, title, assignment_opts)
        opts[:module_item__content_id__] = assignment_res['id']
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'Assignment', assignment_res['id'], opts)
        section.lms_assignment_id = assignment_res['id']
        section.lms_item_id = res['id']
        section.save
      end
    else
      if section.lms_item_id
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      else
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'ExternalTool', '', opts)
        section.lms_item_id = res['id']
        section.save
      end
    end

  end


  # -------------------------------------------------------------
  # If OpenDSA section is gradable, it has only one exercises with points greater than zero.
  # in canvas, module item that refer to an assignment will map OpenDSA gradable section
  def save_section_as_assignment(client, lms_course_id, chapter, section, title, opts, url_opts)

    if section.gradable
      gradable_ex = section.get_gradable_ex
      url_opts[:custom_ex_name] = gradable_ex['ex_name']
      url_opts[:custom_inst_bk_sec_ex] = gradable_ex['inst_bk_sec_ex']
      url_opts[:custom_section_title] = title
    end

    uri = Addressable::URI.new
    uri.query_values = url_opts

    assignment_opts = {
      :assignment__name__ => title,
      :assignment__submission_types__ => "external_tool",
      :assignment__external_tool_tag_attributes__ => {:url => @odsa_launch_url + '?' + uri.query },
      :assignment__assignment_group_id__ => chapter.lms_assignment_group_id,
      :assignment__description__ => title
    }

    opts[:module_item__title__] = title
    if section.gradable
      assignment_opts[:assignment__points_possible__] = InstBookSectionExercise.where("inst_section_id = ? AND points > 0", section.id).first.points
      opts[:module_item__type__] = 'Assignment'
      if section.lms_item_id && section.lms_assignment_id
        opts[:module_item__content_id__] = section.lms_assignment_id
        assignment_res = client.edit_assignment(lms_course_id, section.lms_assignment_id, assignment_opts )
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      else
        assignment_res = client.create_assignment(lms_course_id, title, assignment_opts)
        opts[:module_item__content_id__] = assignment_res['id']
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'Assignment', assignment_res['id'], opts)
        section.lms_assignment_id = assignment_res['id']
        section.lms_item_id = res['id']
        section.save
      end
    else
      if section.lms_item_id
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      else
        res = client.create_module_item(lms_course_id, chapter.lms_chapter_id, 'ExternalTool', '', opts)
        section.lms_item_id = res['id']
        section.save
      end
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


    sanitize_filename(organization.slug)+"/"+
    sanitize_filename(course.slug)+"/"+
    sanitize_filename(term.slug)+"/"+
    sanitize_filename(course_offering.label)

  end



end