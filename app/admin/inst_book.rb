ActiveAdmin.register InstBook, sort_order: :created_at_asc do
  filter :template
  includes :course_offering, :user
  config.clear_action_items!
  actions :all, except: [:new]

  menu label: "Book Instances", parent: 'OpenDSA Books', priority: 20
  permit_params :template, :title, :desc, :course_offering_id, :user_id, :book_type

  member_action :update_configuration, method: :get do
  end


  member_action :clone_book, method: :get do
    inst_book = InstBook.find(params[:id])
    title = inst_book.title
    cloned_inst_book = inst_book.clone(current_user)
    redirect_to admin_inst_books_path, notice: "Book instance ID:'#{inst_book.id}' title:'#{title}' was cloned successfully!. The new Book Instance ID is '#{cloned_inst_book.id}'"
  end

  member_action :destroy_book, method: :delete do
    inst_book = InstBook.find(params[:id])
    title = inst_book.title
    inst_book.destroy
    redirect_to admin_inst_books_path, notice: "Book configuration '#{title}' was deleted successfully!"
  end

  collection_action :upload_books, method: :get do
  end

  collection_action :upload_create, method: :post do
  end

  action_item :index, only: :index do |inst_book|
    link_to 'Upload Books', upload_books_admin_inst_books_path(inst_book)
  end

  action_item :show, only: :show  do
    link_to "Clone", clone_book_admin_inst_book_path(inst_book)
  end

  action_item :view, only: [:show, :edit]  do
    message = confirmation_message(inst_book)
    link_to "Delete", { action: :destroy }, method: :delete, data: { confirm: message}
  end

  controller do
    def scoped_collection
      InstBook.joins(:course_offering).where('course_offerings.archived = false').
      union(InstBook.where("template = ? or course_offering_id is null", 1))
    end

    def update_configuration
      if !authorized? :update_configuration
        redirect_to admin_inst_books_path
      end
      @inst_book = InstBook.find(params[:id])
      render 'upload_books'
    end

    def upload_books
      if !current_user.global_role.is_admin? and !current_user.global_role.is_instructor?
        redirect_to admin_inst_books_path
      end
    end

    def upload_create
      uploaded_file = params[:form][:file]
      File.open(Rails.root.join('public', 'OpenDSA', 'config', 'temp', uploaded_file.original_filename), 'wb') do |file|
        file.write(uploaded_file.read)
      end
      input_file = "public/OpenDSA/config/temp/#{uploaded_file.original_filename}"
      output_file = sanitize_filename('temp_' + current_user.id.to_s + '_' + Time.now.getlocal.to_s) + '_full.json'
      output_file_path = "public/OpenDSA/config/temp/#{output_file}"
      output_path = output_file_path[15..-1] # without the public/OpenDSA
      input_path = input_file[15..-1] # without the public/OpenDSA
      require 'net/http'
      uri = URI(ENV["simple_api_link"])
      res = Net::HTTP.post_form(uri, 'input_path' => input_path, 'output_path' => output_path, 'rake' => false)

      unless res.kind_of? Net::HTTPSuccess
        Rails.logger.info(res['stderr_compressed'])
      end
      hash = JSON.load(File.read(output_file_path))
      if params.has_key?(:inst_book)
        InstBook.save_data_from_json(hash, current_user, params[:inst_book]["id"])
      else
        InstBook.save_data_from_json(hash, current_user)
      end

      redirect_to admin_inst_books_path, notice: 'Book configuration uploaded successfully!'
    end

    # --------------------------------------------------------------------------
    # inst_book cannot be template and linked to a course offering at the same time
    # in such cases reset the template flag
    def data_check(inst_book)
      if inst_book.course_offering_id and inst_book.template
        inst_book.template = false
      end
    end

    def sanitize_filename(filename)
      filename.gsub(/[^\w\s_-]+/, '')
                    .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
                    .gsub(/\s+/, '_')
    end
  end

  before_save :data_check

  index do
    id_column
    column :title
    # column :desc
    column 'Template?', :template
    if current_user.global_role.is_admin?
      column "Owner", :user
    end
    column :course_offering
    column :last_compiled
    column "Actions" do |inst_book|
      message = confirmation_message(inst_book)
      links = ''.html_safe
      if authorized? :update, inst_book
        links += link_to "Edit", edit_admin_inst_book_path(inst_book)
        links += ' '
      end
      if authorized? :destroy, inst_book
        links += link_to "Delete", destroy_book_admin_inst_book_path(inst_book), method: :delete, data: {confirm: message}
        links += ' '
      end
      links += link_to "Clone", clone_book_admin_inst_book_path(inst_book)
      if authorized? :update_configuration, inst_book
        links += link_to "Update Configuration", update_configuration_admin_inst_book_path(inst_book)
        links += ' '
      end
      links
    end

  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      if !f.object.template
        if f.object.last_compiled == nil or (f.object.last_compiled != nil and current_user.global_role.is_admin?)
          f.input :course_offering
        end
      end
      if current_user.global_role.is_admin?
        f.input :user
        if f.object.course_offering_id == nil
          f.input :template
        end
      end
      if current_user.global_role.is_admin?
        f.input :book_type, as: :select, collection: InstBook.book_types.keys
      end
      f.input :title
      f.input :desc
    end
    f.actions
  end

end
