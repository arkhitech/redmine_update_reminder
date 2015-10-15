every 1.hour do
  rake 'intouch:email:send_reminders'
end

every 1.day, at: '10:00' do
  rake 'intouch:regular_notification:overdue'
end

every 3.hours do
  rake 'intouch:regular_notification:unassigned'
end

every 5.minutes do
  rake 'intouch:regular_notification:working_and_feedback'
end
