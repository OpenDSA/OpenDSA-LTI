Rails.application.routes.draw do
  mount Upmin::Engine => '/admin'
  root to: 'visitors#index'
  devise_for :users
  resources :users

  post 'lti/launch'

  post 'lti/assessment'

  get 'configurations/book/create'

  post 'configurations/book/create'

  get 'configurations/book/modules'

end
