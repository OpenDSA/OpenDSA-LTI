# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']
set :output, "/home/deploy/OpenDSA-LTI/current/log/cron_log.log"
every :reboot do
  command "cd /home/deploy/OpenDSA-LTI/current && RAILS_ENV=production bin/delayed_job -n 2 start"
end

every 1.day, :at => '5:00 am' do
  command "cd /home/deploy/OpenDSA-LTI/current && RAILS_ENV=production bin/delayed_job -n 2 restart"
  command "ps aux | grep puma | awk '{print $2}' | xargs kill -9"
  command "cd /home/deploy/OpenPOP && ./runprod.sh"
end
