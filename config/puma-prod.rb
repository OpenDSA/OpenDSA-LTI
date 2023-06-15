workers 4
threads 8, 8
daemonize false
port 8443

app_dir = File.expand_path('../..', __FILE__)

rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

stdout_redirect(stdout = '/dev/stdout', stderr = '/dev/stderr', append = true)

# Set master PID and state locations
# requires mkdir -p tmp/pids so not included for now
# pidfile "#{app_dir}/tmp/pids/puma.pid"
# state_path "#{app_dir}/tmp/pids/puma.state"
# activate_control_app

on_worker_boot do
  require 'active_record'
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(
    YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end
