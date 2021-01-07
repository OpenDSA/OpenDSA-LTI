# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
require 'capistrano/rails'
require 'capistrano/rake'
require 'capistrano/bower'
require 'capistrano/bundler'
require 'capistrano/passenger'
require 'capistrano/rbenv'
require 'capistrano/delayed_job'
require 'capistrano/figaro_yml'
require 'whenever/capistrano'
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

set :rbenv_type, :user
set :rbenv_ruby, '2.7.1'

# require 'capistrano/passenger'

# require 'capistrano/rvm'
# require 'capistrano/chruby'
# require 'capistrano/rails/assets'
# require 'capistrano/rails/migrations'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
