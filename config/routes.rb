Rails.application.routes.draw do
  # ActiveAdmin.routes(self)
  root to: 'visitors#index'
  devise_for :users
  resources :users

  post 'lti/launch'

  post 'lti/assessment'

  get 'configurations/book/create'

  post 'configurations/book/create'

  get 'configurations/book/edit'

  post 'configurations/book/edit'

  get 'configurations/book/modules'

  get 'configurations/book/load'

  get 'configurations/book/configs' # Gets the configuration file names that already exist

  # routes anchored at /admin
  # First, we have to override some of the ActiveAdmin auto-generated
  # routes, since our user ids and file ids use restricted characters
  get '/admin/users/:id/edit(.:format)' => 'admin/users#edit',
    constraints: { id: /[^\/]+/ }
  get '/admin/users/:id' => 'admin/users#show',
    constraints: { id: /[^\/]+/ }
  patch '/admin/users/:id' => 'admin/users#update',
    constraints: { id: /[^\/]+/ }
  put '/admin/users/:id' => 'admin/users#update',
    constraints: { id: /[^\/]+/ }
  delete '/admin/users/:id' => 'admin/users#destroy',
    constraints: { id: /[^\/]+/ }
  ActiveAdmin.routes(self)

  # All of the routes anchored at /courses
  resources :organizations, only: [ :index, :show ], path: '/courses' do
    get 'search' => 'courses#search', as: :courses_search
    post 'find' => 'courses#find', as: :course_find
    get 'new' => 'courses#new'
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

  resources :course_offerings, only: [ :edit, :update ] do
    post 'enroll' => :enroll, as: :enroll
    delete 'unenroll' => :unenroll, as: :unenroll
    match 'upload_roster/:action', controller: 'upload_roster',
      as: :upload_roster, via: [:get, :post]
    post 'generate_gradebook' => :generate_gradebook, as: :gradebook
    get 'add_workout' => :add_workout, as: :add_workout
    post 'store_workout/:id' => :store_workout, as: :store_workout
  end

  # All of the routes anchored at /users
  resources :users, constraints: { id: /[^\/]+/ } do
    resources :resource_files, path: 'media',
      constraints: { id: /[^\/]+/ }
    # This route is broken, since there is no such method
    # post 'resource_files/uploadFile' => 'resource_files#uploadFile'
    get 'performance' => :calc_performance, as: :calc_performance
  end

end
