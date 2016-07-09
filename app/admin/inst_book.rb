ActiveAdmin.register InstBook, sort_order: :title_asc do
  includes :course_offering, :user
  # active_admin_import
  actions :all, except: [:new]

  menu parent: 'ODSA Books', priority: 20
  permit_params :title, :desc, :user_id

  # belongs_to :course_offering

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
  end

  index do
    id_column
    column :title
    column :desc
    if current_user.global_role.is_admin?
      column "Owner", :user
    end
    column :course_offering
    column :created_at
    actions defaults: true do |inst_book|
      link_to "Clone", clone_admin_inst_book_path(inst_book)
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :course_offering
      if current_user.global_role.is_admin?
        f.input :user
        f.input :template
      end
      f.input :title
      f.input :desc
    end
    f.actions
  end


end
