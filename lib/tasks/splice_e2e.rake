# Local end-to-end test of the SPLICE relay (KA exercise -> odsaMOD -> server)
# in OpenDSA-DevStack, without Canvas. Development only.
#
#   rake splice_e2e:setup                 # import + compile the test book
#   rake splice_e2e:launch[student_email] # write a signed LTI launch page
#
# Then run the browser driver from the OpenDSA repo:
#   node tools/splice-e2e/lti_e2e.mjs
# See tools/splice-e2e/README.md in the OpenDSA repo.
module SpliceE2e
  BOOK_TITLE = 'SPLICE Relay Test'
  SIMPLE_CONFIG = 'tools/splice-e2e/SpliceRelayTest.json'   # relative to /opendsa
  FULL_CONFIG = 'config/temp/SpliceRelayTest_full.json'     # relative to /opendsa
  MODULE_PATH = 'AlgAnal/AnalMisunderstanding'
  MODULE_FILE = 'AnalMisunderstanding'
  LAUNCH_URL = 'https://opendsa-lti.localhost.devcom.vt.edu/lti/launch'
  LAUNCH_PAGE = 'Books/splice-e2e/launch.html'              # relative to /opendsa
  COMPILE_TIMEOUT = 15.minutes

  module_function

  def guard!
    abort 'splice_e2e tasks only run in development' unless Rails.env.development?
  end

  def instructor
    User.find_by(email: 'example-1@railstutorial.org') ||
      abort('Seeded instructor not found: run `rake db:populate` first')
  end

  def lms_access
    LmsAccess.find_by(user_id: instructor.id) ||
      abort('No LTI keys (LmsAccess) for the instructor: run `rake db:populate` first')
  end

  # The first seeded offering on the LMS instance the instructor has keys for
  def course_offering
    CourseOffering.where(lms_instance_id: lms_access.lms_instance_id).order(:id).first ||
      abort('No course offering found: run `rake db:populate` first')
  end

  def book
    InstBook.where(title: BOOK_TITLE, template: false).order(:id).last
  end

  # The same path CompileBookJob builds the book into (with spaces as
  # underscores, as the built directory is named)
  def book_path(inst_book)
    CompileBookJob.allocate.send(:book_path, inst_book).gsub(' ', '_')
  end

  def module_page(inst_book)
    File.join('/opendsa/Books', book_path(inst_book), 'lti_html', "#{MODULE_FILE}.html")
  end
end

namespace :splice_e2e do
  desc 'Import and compile the SPLICE relay test book (development only)'
  task setup: :environment do
    SpliceE2e.guard!
    api = ENV['config_api_link'] || abort('config_api_link is not set')

    # 1. Expand the simple book config (the opendsa container runs the tool)
    require 'net/http'
    res = Net::HTTP.post_form(URI(api.sub('/configure/', '/simple2full/')),
                              'input_path' => SpliceE2e::SIMPLE_CONFIG,
                              'output_path' => SpliceE2e::FULL_CONFIG, 'rake' => 'false')
    full_path = File.join('/opendsa', SpliceE2e::FULL_CONFIG)
    unless res.is_a?(Net::HTTPSuccess) && File.exist?(full_path)
      abort "simple2full failed (#{res.code}): #{res.body[0, 300]}"
    end

    # 2. Import it and attach a copy to the course offering
    inst_book = SpliceE2e.book
    if inst_book
      puts "Test book already imported (inst_book #{inst_book.id})"
    else
      InstBook.save_data_from_json(JSON.parse(File.read(full_path)), SpliceE2e.instructor)
      template = InstBook.where(title: SpliceE2e::BOOK_TITLE, template: true).order(:id).last
      inst_book = template.clone(SpliceE2e.instructor)
      inst_book.course_offering_id = SpliceE2e.course_offering.id
      inst_book.save!
      puts "Imported test book: inst_book #{inst_book.id} on course offering #{inst_book.course_offering_id}"
    end

    # 3. Compile it the way the instructor's "compile book" button does
    #    (a background job, run by the jobs:work worker) and wait for it
    page = SpliceE2e.module_page(inst_book)
    File.delete(page) if File.exist?(page)
    Delayed::Job.enqueue CompileBookJob.new(inst_book.id, SpliceE2e::LAUNCH_URL.sub('/launch', '/launch_extrtool'),
                                            SpliceE2e.instructor.id)
    print 'Compiling (needs the jobs:work worker)'
    deadline = Time.now + SpliceE2e::COMPILE_TIMEOUT
    until File.exist?(page)
      abort "\nCompile did not finish: #{page} not found (see the opendsa container log)" if Time.now > deadline
      print '.'
      sleep 5
    end
    puts "\nCompiled: #{page}"
    puts 'Next: rake splice_e2e:launch'
  end

  desc 'Write a signed LTI launch page for the test book (development only)'
  task :launch, [:student_email] => :environment do |_t, args|
    SpliceE2e.guard!
    require 'ims/lti'
    email = args[:student_email] || 'example-2@railstutorial.org'
    student = User.find_by(email: email) || abort("Student #{email} not found")
    inst_book = SpliceE2e.book || abort('Run `rake splice_e2e:setup` first')
    cm = InstChapterModule.joins(:inst_module, :inst_chapter)
                          .where(inst_chapters: {inst_book_id: inst_book.id},
                                 inst_modules: {path: SpliceE2e::MODULE_PATH}).first!

    access = SpliceE2e.lms_access
    tc = IMS::LTI::ToolConsumer.new(access.consumer_key, access.consumer_secret)
    tc.launch_url = SpliceE2e::LAUNCH_URL
    tc.resource_link_id = "splice-e2e-#{cm.id}"
    tc.user_id = "splice-e2e-#{student.id}"
    tc.roles = 'Learner'
    tc.lis_person_contact_email_primary = student.email
    tc.lis_person_name_given = student.first_name
    tc.lis_person_name_family = student.last_name
    tc.context_id = 'splice-e2e'
    tc.tool_consumer_info_product_family_code = 'canvas'
    {
      'inst_book_id' => inst_book.id,
      'book_path' => SpliceE2e.book_path(inst_book),
      'module_file_name' => SpliceE2e::MODULE_FILE,
      'module_title' => cm.inst_module.name,
      'inst_chapter_module_id' => cm.id,
      'inst_module_id' => cm.inst_module_id,
      'inst_chapter_id' => cm.inst_chapter_id,
    }.each { |k, v| tc.set_custom_param(k, v.to_s) }

    fields = tc.generate_launch_data.map do |k, v|
      %(<input type="hidden" name="#{ERB::Util.h(k)}" value="#{ERB::Util.h(v)}">)
    end
    out = File.join('/opendsa', SpliceE2e::LAUNCH_PAGE)
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, <<~HTML)
      <!DOCTYPE html>
      <html><head><meta charset="utf-8"><title>SPLICE e2e LTI launch</title></head>
      <body>
      <p>Launching #{ERB::Util.h(SpliceE2e::MODULE_PATH)} as #{ERB::Util.h(student.email)}...</p>
      <form id="f" method="post" action="#{SpliceE2e::LAUNCH_URL}">
      #{fields.join("\n")}
      </form>
      <script>document.getElementById('f').submit();</script>
      </body></html>
    HTML
    puts "Wrote #{out} for #{student.email} (valid for 24 hours)"
    puts "Open https://opendsa.localhost.devcom.vt.edu/#{SpliceE2e::LAUNCH_PAGE}"
    puts 'or run (from the OpenDSA repo): node tools/splice-e2e/lti_e2e.mjs'
  end
end
