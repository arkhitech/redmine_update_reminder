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
#set :environment, "production"
#every 15.minutes do
#rake "trackers"
#end
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 30.minutes do
  rake 'intouch:telegram:notification:alarm'
end

every 1.day, at: '10:00' do
  rake 'intouch:telegram:notification:new'
  rake 'intouch:telegram:notification:overdue'
end

every 5.minutes do
  rake 'intouch:telegram:notification:work_in_progress'
end

every 5.minutes do
  rake 'intouch:telegram:notification:feedback'
end
