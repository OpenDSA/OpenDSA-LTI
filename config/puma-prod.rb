daemonize false
debug
port 8443

app_dir = File.expand_path('../..', __FILE__)

rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

stdout_redirect(stdout = '/dev/stdout', stderr = '/dev/stderr', append = true)

on_worker_boot do
  require 'active_record'
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(
    YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end
