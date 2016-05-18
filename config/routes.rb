Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  mount Upmin::Engine => '/admin'
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

end
