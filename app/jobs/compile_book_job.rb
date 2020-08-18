class CompileBookJob < ProgressJob::Base
  def initialize(inst_book_id, extrtool_launch_base_url, user_id)
    @user_id = user_id
    @inst_book = InstBook.find_by(id: inst_book_id)
    @extrtool_launch_base_url = extrtool_launch_base_url
    @course_offering = CourseOffering.where(:id => @inst_book.course_offering_id).first
  end

  def perform
    update_stage('Compiling OpenDSA book')
    inst_book_json = ApplicationController.new.render_to_string(
      template: "inst_books/show.json.jbuilder",
      locals: {:@inst_book => @inst_book, :@extrtool_launch_base_url => @extrtool_launch_base_url},
    )

    require 'json'
    config_file = sanitize_filename('temp_' + @user_id.to_s + '_' + Time.now.getlocal.to_s) + '.json'
    config_file_path = "public/OpenDSA/config/temp/#{config_file}"
    File.open(config_file_path, "w") do |f|
      f.write(inst_book_json)
    end

    script_path = "public/OpenDSA/tools/configure.py"
    build_path = book_path(@inst_book)
    value = %x(. /home/deploy/OpenDSA/.pyVenv/bin/activate && python3 #{script_path} #{config_file_path} -b #{build_path})
    update_progress
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
