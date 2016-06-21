class CompileBookJob < ProgressJob::Base
  def initialize(inst_book_id, launch_url, user_id)
    @user_id = user_id
    @inst_book = InstBook.find_by(id: inst_book_id)
    @launch_url = launch_url
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
    config_file = sanitize_filename('temp_' + @user_id.to_s + '_' + Time.now.getutc.to_s) + '.json'
    config_file_path = "public/OpenDSA/config/#{config_file}"
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
    consumer_key = @inst_book.course_offering.lms_instance['consumer_key']
    consumer_secret = @inst_book.course_offering.lms_instance['consumer_secret']
    privacy_level = "public"
    user_lms_access = LmsAccess.where(lms_instance_id: lms_instance_id).where(user_id: @user_id).first
    lms_course_id = @inst_book.course_offering.lms_course_num

    require 'pandarus'
    client = Pandarus::Client.new(
      prefix: @inst_book.course_offering.lms_instance.url + '/api',
      token: user_lms_access.access_token)

    # create LTI tool in canvas if it is not defined
    if !@inst_book.course_offering.lms_tool_num || @inst_book.course_offering.lms_tool_num = 0
      res = client.create_external_tool_courses(lms_course_id, "OpenDSA-LTI", privacy_level, consumer_key, consumer_secret, {:url => @launch_url})
      @inst_book.course_offering.lms_tool_num = res["id"]
      @inst_book.course_offering.save
    end

    # generate canvas course modules, items and assignments out of inst_book configurations
    save_lms_course(client, lms_course_id)
  end

  # -------------------------------------------------------------
  # Create canvas modules that maps to OpenDSA chapters
  def save_lms_course(client, lms_course_id)

    chapters = InstChapter.where(inst_book_id: @inst_book.id)

    chapters.each do |chapter|
      opts = {:module__name__ => 'Chapter '+ chapter.position.to_s + ' ' + chapter.name,
                   :module__position__ => chapter.position}

      update_stage('Generating: ' + opts[:module__name__])

      if chapter.lms_chapter_id
        opts[:module__published__] = true
        res = client.update_module(lms_course_id, chapter.lms_chapter_id, opts)
      else
        res = client.create_module(lms_course_id, chapter.name, opts)
        chapter.lms_chapter_id = res['id']
        chapter.save
        opts[:module__published__] = true
        res = client.update_module(lms_course_id, chapter.lms_chapter_id, opts)
      end

      save_lms_chapter(client, lms_course_id, chapter)
      update_progress
    end
  end

  # -------------------------------------------------------------
  # For each canvas module, create text items (just a label) that maps to OpenDSA modules
  def save_lms_chapter(client, lms_course_id, chapter)

    modules = InstChapterModule.where(inst_chapter_id: chapter.id)

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

    if !sections.empty?
      sections.each do |section|
        save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                                         section, module_item_position, section_item_position)
        section_item_position += 1
      end
    else
      save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                                       nil, module_item_position, section_item_position)
    end

    module_item_position + section_item_position

  end

  # -------------------------------------------------------------
  # in canvas, module item that has external link will map OpenDSA non-gradable section
  def save_section_as_external_tool(client, lms_course_id, chapter, inst_ch_module,
                                                          section, module_item_position, section_item_position)

    module_name = InstModule.where(:id => inst_ch_module.inst_module_id).first.path
    if module_name.include? '/'
      module_name = module_name.split('/')[1]
    end

    if section
      section_file_name = module_name + "-" + section_item_position.to_s.rjust(2, "0")
    else
      section_file_name = module_name
    end

    title = (chapter.position.to_s.rjust(2, "0")||"")+"."+
               (inst_ch_module.module_position.to_s.rjust(2, "0")||"")+"."+
               section_item_position.to_s.rjust(2, "0")+" - "
    title = (title + InstModule.where(:id => inst_ch_module.inst_module_id).first.name) if !section else title

    url_opts = {
      :inst_book_id => @inst_book.id,
      :inst_section_id => (section.id if section),
      :book_path => book_path(@inst_book),
      :section_file_name => section_file_name,
      :section_title => title
    }

    require "addressable/uri"
    uri = Addressable::URI.new
    uri.query_values = url_opts

    opts = {:module_item__title__ => title,
                  :module_item__type__ => 'ExternalTool',
                  :module_item__position__ => module_item_position + section_item_position,
                  :module_item__external_url__ => @launch_url + '?' + uri.query,
                  :module_item__indent__ => 1
                }

    if section
      save_section_as_assignment(client, lms_course_id, chapter, section, title, opts, url_opts)
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


  # -------------------------------------------------------------
  # If OpenDSA section is gradable, it has only one exercises with points greater than zero.
  # in canvas, module item that refer to an assignment will map OpenDSA gradable section
  def save_section_as_assignment(client, lms_course_id, chapter, section, title, opts, url_opts)

    if section.gradable
      gradable_ex = section.get_gradable_ex
      url_opts[:ex_name] = gradable_ex['ex_name']
      url_opts[:inst_bk_sec_ex] = gradable_ex['inst_bk_sec_ex']
      url_opts[:section_title] = title + section.name
    end

    uri = Addressable::URI.new
    uri.query_values = url_opts

    assignment_opts = {
      :assignment__name__ => title + section.name,
      :assignment__submission_types__ => "external_tool",
      :assignment__external_tool_tag_attributes__ => {:url => @launch_url + '?' + uri.query },
    }

    opts[:module_item__title__] = title + section.name
    if section.gradable
      assignment_opts[:assignment__points_possible__] = InstBookSectionExercise.where("inst_section_id = ? AND points > 0", section.id).first.points
      opts[:module_item__type__] = 'Assignment'
      if section.lms_item_id && section.lms_assignment_id
        opts[:module_item__content_id__] = section.lms_assignment_id
        assignment_res = client.edit_assignment(lms_course_id, section.lms_assignment_id, assignment_opts )
        res = client.update_module_item(lms_course_id, chapter.lms_chapter_id, section.lms_item_id, opts)
      else
        assignment_res = client.create_assignment(lms_course_id, title + section.name, assignment_opts)
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