# config valid only for Capistrano 3.10.1
lock '3.14.1'

set :application, 'OpenDSA-LTI'
set :repo_url, 'git://github.com/OpenDSA/OpenDSA-LTI.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/deploy/OpenDSA-LTI'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :linked_files, %w{config/database.yml config/secrets.yml config/application.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

set :bower_flags, '--quiet --config.interactive=false'
set :bower_roles, :web
# set :bower_target_path, nil
# set :bower_target_path, "#{release_path}"
set :bower_bin, :bower

set :passenger_restart_with_touch, true

# delayed_job

# Number of delayed_job workers
# default value: 1
set :delayed_job_workers, 2

# String to be prefixed to worker process names
# This feature allows a prefix name to be placed in front of the process.
# For example:  reports/delayed_job.0  instead of just delayed_job.0
# set :delayed_job_prefix, 'reports'

# Delayed_job queue or queues
# Set the --queue or --queues option to work from a particular queue.
# default value: nil
# set :delayed_job_queues, ['mailer','tracking']

# Specify different pools
# You can use this option multiple times to start different numbers of workers
# for different queues.
# NOTE: When using delayed_job_pools, the settings for delayed_job_workers and
# delayed_job_queues are ignored.
# default value: nil
#
# Single pool of 3 workers looking at all queues: (when alone, '*' is a
# special case meaning any queue)
# set :delayed_job_pools, { '*' => 3 }
# set :delayed_job_pools, { '' => 3 }
# set :delayed_job_pools, { nil => 3 }
#
# Several queues, some with their own dedicated pools: (symbol keys will be
# converted to strings)
# set :delayed_job_pools, {
#     :mailer => 2,    # 2 workers looking only at the 'mailer' queue
#     :tracking => 1,  # 1 worker exclusively for the 'tracking' queue
#     :* => 2          # 2 on any queue (including 'mailer' and 'tracking')
# }
#
# Several workers each handling one or more queues:
# set :delayed_job_pools, {
#     'high_priority' => 1,                # one just for the important stuff
#     'high_priority,*' => 1,              # never blocked by low_priority jobs
#     'high_priority,*,low_priority' => 1, # works on whatever is available
#     '*,low_priority' => 1,  # high_priority doesn't starve the little guys
#   }
# Identification is assigned in order 0..3.
# Note that the '*' in this case is actually a queue with that name and does
# not mean any queue as it is not used alone, but alongside other queues.

# Set the roles where the delayed_job process should be started
# default value: :app
# set :delayed_job_roles, [:app, :background]

# Set the location of the delayed_job executable
# Can be relative to the release_path or absolute
# default value: 'bin'
# set :delayed_job_bin_path, 'script' # for rails 3.x

# To pass the `-m` option to the delayed_job executable which will cause each
# worker to be monitored when daemonized.
# set :delayed_job_monitor, true

### Set the location of the delayed_job.log logfile
# default value: "#{Rails.root}/log" or "#{Dir.pwd}/log"
# set :delayed_log_dir, 'path_to_log_dir'

### Set the location of the delayed_job pid file(s)
# default value: "#{Rails.root}/tmp/pids" or "#{Dir.pwd}/tmp/pids"
# set :delayed_job_pid_dir, 'path_to_pid_dir'

# after 'deploy:pull_opendsa', 'db:delete_templates'

# namespace :db do
#   desc "remove template books"
#   task :delete_templates do
#     on roles(:all) do
#       within release_path do
#         with rails_env: fetch(:rails_env) do
#           execute :rake, 'db:delete_templates'
#         end
#       end
#     end
#   end
# end

namespace :deploy do
  desc 'Restart application'

  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'

  # Link OpenDSA to public
  after :finishing, 'deploy:update_code' do
    on roles :all do
      execute :ln, "-s /home/deploy/OpenDSA #{current_path}/public"
    end
  end

  # pull the latest from OpenDSA repository
  after :finishing, 'deploy:pull_opendsa' do
    on roles :all do
      execute "cd ~/OpenDSA; git checkout $(echo $opendsa_branch); make pull;"
    end
  end

  # manually checkout master for khan-exercises repository
  after :finishing, 'deploy:checkout_ka' do
    on roles :all do
      execute "cd ~/OpenDSA/khan-exercises; git checkout $(echo $opendsa_branch); git pull;"
    end
  end

  # update or create stand-alone module versions
  after :finishing, 'deploy:update_module_versions' do
    on roles :all do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'update_module_versions'
        end
      end
    end
  end

  # clear cache entries that may now be outdated
  after :finishing, 'deploy:clear_rails_cache' do
    on roles :all do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'clear_rails_cache'
        end
      end
    end
  end

end
