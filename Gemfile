source 'https://rubygems.org'

gem 'rails', '~> 6.0', '>= 6.0.3.1'
gem 'bootstrap-sass', '>= 3.4.1'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'bootstrap-editable-rails'
gem 'font-awesome-rails'
gem 'formtastic', '~> 3.1'
gem 'formtastic-bootstrap'
#gem 'sidekiq'
gem 'sucker_punch', '~> 1.0'

# Create JSON structures via a Builder-style DSL
gem 'jbuilder', '~> 2.10'
gem 'haml', '>= 3.1.4'
gem 'haml-rails'
gem 'coffee-rails', '~> 5.0'
gem 'coffee-script-source'
gem 'test-unit', '~> 3.0.9'
gem 'csv_shaper'
gem 'andand', github: 'raganwald/andand'
#gem 'foreigner'
gem 'responders'
gem 'friendly_id', '~> 5'
gem 'active_record-acts_as'
gem 'acts_as_list'
gem 'acts-as-taggable-on'
gem 'representable'
gem 'redcarpet'

gem 'loofah', '2.5.0' # Rails 5.2
gem 'sprockets', '3.7.2' # 4.0 requires ruby 2.5
gem 'i18n', '1.8.2'
gem 'json', '2.3.0'
gem 'rack', '2.2.2'
gem 'rack-test', '1.1.0'
gem 'rake', '13.0.1'

gem 'truncate_html'
gem 'puma', '~> 4.3.1'
gem 'tzinfo' # For timezone support

# Bootstrap Datepicker
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.14.30'

# Addressable is a replacement for the URI implementation that is part of Ruby's standard library.
# It more closely conforms to the relevant RFCs and adds support for IRIs and URI templates.
gem 'addressable', '~> 2.3', '>= 2.3.8'

gem 'daemons'
gem 'delayed_job_active_record'
gem 'progress_job'


# For JSON support
gem 'rabl'
gem 'oj'
gem 'oj_mimic_json'

group :assets do
  gem 'sass-rails'
  gem 'uglifier', '~> 4.2'
  gem 'autoprefixer-rails'
end

gem 'mysql2'

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails', '>=3.4.2'
  gem 'annotate'
  gem 'rails-erd', github: 'voormedia/rails-erd'
  gem 'pry'
  gem 'thin'
  gem 'request-log-analyzer'
  # gem 'byebug'
  gem 'debase'
  gem 'ruby-debug-ide'
end

gem 'faker'
gem 'factory_bot_rails'
gem 'log_file'

group :test do
  gem 'capybara'
end

group :production, :staging do

end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Gems for authentication and authorization.
gem 'devise', '~> 4.7.1'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-cas'
gem 'cancancan'
gem 'activeadmin', '~> 2.7'
# update this gem
gem 'exception_handler', '~> 0.3.45'

gem 'nokogiri', '1.11.0', require: false
gem 'oauth', '0.5.4', require: false
gem 'oauth2', '1.4.4', require: false

gem 'kaminari'        # Auto-paginated views
gem 'remotipart'      # Adds support for remote mulitpart forms (file uploads)
gem 'gravtastic'      # For Gravatar integration
gem 'js-routes'       # Route helpers in Javascript
gem 'awesome_print'   # For debugging/logging output


#gems for rich text editing
gem 'bootstrap-wysihtml5-rails'

#gem for improved WHERE querying
#gem 'squeel'

#for nested forms
gem 'cocoon'

# For handling converting to booleans
gem 'wannabe_bool'

# Gems for deployment.
gem 'capistrano3-delayed-job', '~> 1.0'
gem 'capistrano-bower'
gem 'capistrano'
gem 'capistrano-figaro-yml', '~> 1.0.2'
gem 'capistrano-bundler'
gem 'capistrano-rails'
gem 'capistrano-rbenv', github: "capistrano/rbenv"
gem 'capistrano-passenger'
gem 'capistrano-rake', require: false
gem 'net-ssh', :github => 'net-ssh/net-ssh'

#for multi-color progress bar
gem 'css3-progress-bar-rails'

gem 'immigrant'
# gem 'ims-lti', '2.3.0', require: 'ims'
gem 'ims-lti', '~> 1.2'
gem "browser"
gem "figaro"
gem 'data-confirm-modal'
gem 'active_record_union'
gem 'jstree-rails-4', '~> 3.2', '>= 3.2.1'
gem 'ransack', '~> 2.3', '>= 2.3.2'
# Bug with version: '~>0.7.0'. The Canvas Tool Creation does not work properly.
# client.create_external_tool_courses() - Missing arguments when tool is added to Canvas.
gem 'pandarus', '~> 0.6.7'

gem 'clipboard-rails'
gem "mustache", "~> 1.0"
gem "whenever", :require => false

#for setting SameSite=None to cookies generated
#gem 'user_agent_parser', '< 2.5.2' # 2.6.0 or higher requires ruby>=2.4
gem 'user_agent_parser' # 2.6.0 or higher requires ruby>=2.4

gem 'rails_same_site_cookie'
gem 'rack-cors'
gem 'simple_oauth', '0.3.1'