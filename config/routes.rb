Rails.application.routes.draw do
  ActiveAdmin.routes(self)
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

  post 'lti/exercise_attempts'

  post 'lti/user_interaction'

  post 'lti/exercise_progress'

  post 'lti/book_progress'

  post 'lti/user_module'


end
