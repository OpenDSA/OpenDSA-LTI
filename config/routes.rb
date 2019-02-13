OpenDSA::Application.routes.draw do
  root 'home#index'

  post 'lti/launch'
  post 'lti/assessment'
  get 'lti/xml_config', to: 'lti#xml_config', as: :xml_config
  get 'lti/resource_dev', to: 'lti#resource_dev', as: :lti_resource_dev
  post 'lti/resource', to: 'lti#resource', as: :lti_resource
  post 'lti/content_item_selection', to: 'lti#content_item_selection', as: :lti_content_item_selection
  post 'lti/course_offering', to: 'lti#create_course_offering', as: :lti_course_offering
  get 'lti/launch_extrtool/:inst_book_section_exercise_id', to: 'lti#launch_extrtool', as: :lti_launch_extrtool
  post 'lti/outcomes', to: 'lti#grade_passback', as: :lti_grade_passback

  resources :odsa_user_interactions
  resources :odsa_exercise_attempts
  # resources :odsa_exercise_progresses
  get '/odsa_exercise_progresses/:inst_book_id/:inst_section_id/:exercise_name' => 'odsa_exercise_progresses#show_exercise'
  get '/odsa_exercise_progresses/' => 'odsa_exercise_progresses#show_exercise'
  get '/odsa_exercise_progresses/:inst_course_offering_exercise_id' => 'odsa_exercise_progresses#show_exercise',
      constraints: {inst_course_offering_exercise_id: /\d+/}
  get '/odsa_exercise_progresses/:inst_book_id/:inst_section_id' => 'odsa_exercise_progresses#show_section'
  get '/odsa_exercise_progresses/get_count' => 'odsa_exercise_progresses#get_count'
  post '/odsa_exercise_progresses' => 'odsa_exercise_progresses#update'
  post '/odsa_exercise_attempts/pe' => 'odsa_exercise_attempts#create_pe'
  # get '/odsa_exercise_attempts/get_count' => 'odsa_exercise_attempts#get_count'

  #me
  #get '/Display' => 'course_offerings#postData'
  #get '/course_offerings/:id/Display' => 'course_offerings#postData'
  #post '/show' => 'course_offerings#postData'
  #me end

  # namespace path_helper hackery!
  # get '/v1/inst_books/:id', to: 'inst_books#show', as: :inst_book

  get 'home' => 'home#index'
  get 'main' => 'home#index'
  get 'home/about'
  get 'home/license'
  get 'home/contact'
  get 'home/guide'
  get 'home/books'
  get 'home/papers'
  get 'home/support'
  get 'home/new_course_modal', as: :new_course_modal

  scope :guides do
    get 'opendsa-bookinstance' => 'guides#opendsa-bookinstance', as: :guide_bookinstance
    get 'opendsa-canvas' => 'guides#opendsa-canvas', as: :guide_canvas
    get 'opendsa-moodle' => 'guides#opendsa-moodle', as: :guide_moodle
    get 'opendsa-book-configuration' => 'guides#opendsa-book-configuration', as: :guide_book_configuration
    get 'opendsa-embed' => 'guides#opendsa-embed', as: :guide_embed
  end

  # routes anchored at /admin
  # First, we have to override some of the ActiveAdmin auto-generated
  # routes, since our user ids and file ids use restricted characters
  get '/admin/users/:id/edit(.:format)' => 'admin/users#edit', constraints: {id: /[^\/]+/}
  get '/admin/users/:id/edit_access(.:format)' => 'admin/users#edit_access', constraints: {id: /[^\/]+/}
  get '/admin/users/:id' => 'admin/users#show', constraints: {id: /[^\/]+/}
  patch '/admin/users/:id' => 'admin/users#update', constraints: {id: /[^\/]+/}
  put '/admin/users/:id' => 'admin/users#update', constraints: {id: /[^\/]+/}
  delete '/admin/users/:id' => 'admin/users#destroy', constraints: {id: /[^\/]+/}
  ActiveAdmin.routes(self)

  post 'inst_books/update' => 'inst_books#update', as: :book_update
  post 'inst_books/:id' => 'inst_books#compile', defaults: {format: 'js', data: {type: "script"}}, as: :compile
  get 'inst_books/:id/validate' => 'inst_books#validate_configuration', as: :book_validate
  get 'inst_books/configure/:id' => 'inst_books#configure', as: :book_configure
  get 'inst_books/configurations/:id' => 'inst_books#configuration', as: :book_configuration
  resources :inst_books

  # book configuration interface
  namespace :configurations do
    get 'book' => 'book#show'
  end

  get 'sse/feedback_wait'
  get 'sse/feedback_poll'
  post '/course_offerings/:id/upload_roster' => 'course_offerings#upload_roster'
  get '/course_offerings/new' => 'course_offerings#new', as: :new_course_offerings
  post '/course_offerings' => 'course_offerings#create', as: :create_course_offerings
  get '/course_offerings/:id' => 'course_offerings#show', as: :show_course_offerings
  get '/course_offerings/:user_id/:inst_section_id' => 'course_offerings#find_attempts', as: :find_attempts
  get '/course_offerings/:id/modules/:inst_chapter_module_id/progresses' => 'course_offerings#find_module_progresses', as: :find_module_progresses
  get '/course_offerings/:user_id/:id/exercise_list' => 'course_offerings#get_individual_attempt', as: :get_individual_attempt
  get '/lms_accesses/:lms_instance_id/search' => 'lms_accesses#search', as: :lms_access_search
  get '/request_extension' => 'workout_offerings#request_extension'
  post '/add_extension' => 'workout_offerings#add_extension'

  get '/course_offerings/indAssigment/assignmentList/student/exercise' => 'course_offerings#ind_assigment', as: :ind_assigment

  # All of the routes anchored at /gym
  scope :gym do
    # The top-level gym route
    get '/' => 'workouts#gym', as: :gym

    # /gym/exercises ...
    get 'exercises_import' => 'exercises#upload_yaml'
    post 'exercises_yaml_create' => 'exercises#yaml_create'
    get 'exercises/upload' => 'exercises#upload', as: :exercises_upload
    get 'exercises/download' => 'exercises#download', as: :exercises_download
    post 'exercises/upload_create' => 'exercises#upload_create'
    get 'exercises/upload_mcqs' => 'exercises#upload_mcqs', as: :exercises_upload_mcqs
    post 'exercises/create_mcqs' => 'exercises#create_mcqs'
    get '/exercises/any' => 'exercises#random_exercise', as: :random_exercise
    get 'exercises/:id/practice' => 'exercises#practice', as: :exercise_practice
    patch 'exercises/:id/practice' => 'exercises#evaluate', as: :exercise_evaluate
    post 'exercises/search' => 'exercises#search', as: :search

    # At the bottom, so the routes above take precedence over existing ids
    resources :exercises

    # /gym/workouts ...
    get 'workouts/download' => 'workouts#download'
    get 'workouts/:id/add_exercises' => 'workouts#add_exercises'
    post 'workouts/link_exercises' => 'workouts#link_exercises'
    get 'workouts/new_with_search/:searchkey' => 'workouts#new_with_search', as: :workouts_with_search
    post 'workouts/new_with_search' => 'workouts#new_with_search', as: :workouts_exercise_search
    get 'workouts/:id/practice' => 'workouts#practice', as: :practice_workout
    get 'workouts/:id/evaluate' => 'workouts#evaluate', as: :workout_evaluate
    get 'workouts_dummy' => 'workouts#dummy'
    get 'workouts_import' => 'workouts#upload_yaml'
    post 'workouts_yaml_create' => 'workouts#yaml_create'

    # At the bottom, so the routes above take precedence over existing ids
    resources :workouts
  end

  # All of the routes anchored at /courses
  resources :organizations, only: [:index, :show], path: '/courses' do
    get 'search' => 'courses#search', as: :courses_search
    post 'find' => 'courses#find', as: :course_find
    get 'new' => 'courses#new'
    get 'list' => 'courses#list', as: :course_list
    get ':id/edit' => 'courses#edit', as: :course_edit
    get ':course_id/:term_id/:id/practice(/:exercise_id)' => 'workout_offerings#practice', as: :workout_offering_practice
    get ':course_id/:term_id/:workout_offering_id/:id' => 'exercises#practice', as: :workout_offering_exercise
    patch ':course_id/:term_id/:workout_offering_id/:id' => 'exercises#evaluate', as: :workout_offering_exercise_evaluate
    get ':course_id/:term_id/:workout_offering_id/review/:review_user_id/:id' => 'exercises#practice', as: :workout_offering_exercise_review
    get ':course_id/:term_id/:id' => 'workout_offerings#show', as: :workout_offering
    get ':course_id/:term_id/review/:review_user_id/:id' => 'workout_offerings#review', as: :workout_offering_review
    post ':id/:term_id/generate_gradebook/' => 'courses#generate_gradebook', as: :course_gradebook
    get ':id(/:term_id)' => 'courses#show', as: :course
  end
  post 'organizations' => 'organizations#create', as: :organization_create
  post 'courses' => 'courses#create'

  resources :course_offerings, only: [:edit, :update] do
    # post 'enroll' => :enroll, as: :enroll
    # delete 'unenroll' => :unenroll, as: :unenroll
    match 'upload_roster/:action', controller: 'upload_roster', as: :upload_roster, via: [:get, :post]
    post 'generate_gradebook' => :generate_gradebook, as: :gradebook
    get 'add_workout' => :add_workout, as: :add_workout
    post 'store_workout/:id' => :store_workout, as: :store_workout
  end

  # All of the routes anchored at /users
  resources :users, constraints: {id: /[^\/]+/} do
    resources :resource_files, path: 'media',
                               constraints: {id: /[^\/]+/}
    # This route is broken, since there is no such method
    # post 'resource_files/uploadFile' => 'resource_files#uploadFile'
    # get 'performance' => :calc_performance, as: :calc_performance
  end

  get '/embed' => 'embed#index', as: :embed_index
  get '/embed/:ex_short_name' => 'embed#show', as: :embed_show
  get '/SourceCode/*all' => 'embed#source_code_redirect'

  devise_for :users,
    controllers: {omniauth_callbacks: 'users/omniauth_callbacks', registrations: "registrations"},
    skip: [:registrations, :sessions]
  as :user do
    get '/new_password' => 'devise/passwords#new', as: :new_password
    get '/edit_password' => 'devise/passwords#edit', as: :edit_password
    put '/update_password' => 'devise/passwords#update', as: :update_password
    post '/create_password' => 'devise/passwords#create', as: :create_password
    get '/signup' => 'registrations#new', as: :new_user_registration
    post '/signup' => 'registrations#create', as: :user_registration
    get '/login' => 'devise/sessions#new', as: :new_user_session
    post '/login' => 'devise/sessions#create', as: :user_session
    delete '/logout' => 'devise/sessions#destroy', as: :destroy_user_session
  end
end
