every 1.hour do
  rake 'intouch:email:send_reminders'
end

every 30.minutes do
  rake 'intouch:regular_notification:alarm'
end

every 1.day, at: '10:00' do
  rake 'intouch:regular_notification:new'
  rake 'intouch:regular_notification:overdue'
end

every 5.minutes do
  rake 'intouch:regular_notification:work_in_progress'
end

every 5.minutes do
  rake 'intouch:regular_notification:feedback'
end
