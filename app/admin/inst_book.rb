ActiveAdmin.register InstBook, sort_order: :title_asc do
  includes :course_offering, :user
  # active_admin_import
  config.clear_action_items!
  actions :all, except: [:new]

  menu parent: 'ODSA Books', priority: 20
  permit_params :template, :title, :desc, :course_offering_id, :user_id

  member_action :clone, method: :get do
  end

  collection_action :upload_books, method: :get do
  end

  collection_action :upload_create, method: :post do
  end

  action_item only: :index do
    link_to 'Upload Books', upload_books_admin_inst_books_path()
  end

  action_item only: :show  do
    link_to "Clone", clone_admin_inst_book_path(inst_book)
  end

  action_item only: [:show, :edit]  do
    book_title = inst_book.title
    last_compiled = inst_book.last_compiled
    course_offering = CourseOffering.where(:id => inst_book.course_offering_id)
    if !course_offering.empty?
      course_offering = course_offering.first
      course_offering_name = course_offering.display_name
      lms_course_num = course_offering.lms_course_num
      lms_url = LmsInstance.where(:id => course_offering.lms_instance_id).first.url
    end
    trailer = "Are you sure you want to proceed with the delete?"
    message1 = "You are about to delete '#{book_title}' book instance. "
    message2 = "The book is linked to '#{course_offering_name}' course offering. "
    message3 = "It was last compiled on '#{last_compiled}', and linked to '#{lms_url}' Instance, course number (#{lms_course_num}). If you delete this book the LMS course won't work and you will have to link a new book instance to the course offering and recompile it. "
    message = message1 + trailer
    if !last_compiled and course_offering_name
      message = message1 + message2 + trailer
    elsif last_compiled and course_offering_name
      message = message1 + message2 + message3 + trailer
    end

    link_to "Delete", { action: :destroy }, method: :delete, data: { confirm:  message}
  end


  controller do
    def clone
      @inst_book = InstBook.find(params[:id])
      title = @inst_book.title
      @inst_book.clone(current_user)
      redirect_to admin_inst_books_path, notice: "Instance book '#{title}' was cloned successfully!"
    end

    def upload_books
    end

    def upload_create
      hash = JSON.load(File.read(params[:form][:file].path))
      InstBook.save_data_from_json(hash, current_user)

      redirect_to admin_inst_books_path, notice: 'Book configuration uploaded successfully!'
    end

    # --------------------------------------------------------------------------
    # inst_book cannot be template and linked to a course offering at the same time
    # in such cases reset the template flag
    def data_check(inst_book)
      # inst_book = InstBook.find(params[:id])
      if inst_book.course_offering_id and inst_book.template
        inst_book.template = false
      end
    end
  end

  before_save :data_check

  index do
    id_column
    column :title
    column :desc
    column :template
    if current_user.global_role.is_admin?
      column "Owner", :user
    end
    column :course_offering
    column :last_compiled
    actions defaults: true do |inst_book|
      link_to "Clone", clone_admin_inst_book_path(inst_book)
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      if !f.object.template
        if f.object.last_compiled == nil
          f.input :course_offering
        end
      end
      if current_user.global_role.is_admin?
        f.input :user
        if f.object.course_offering_id == nil
          f.input :template
        end
      end
      f.input :title
      f.input :desc
    end
    f.actions
  end

end