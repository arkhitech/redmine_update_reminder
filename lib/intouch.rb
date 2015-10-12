module Intouch

  def self.work_day?
    settings = Setting.plugin_redmine_intouch
    work_days = settings.keys.select { |key| key.include?('work_days') }.map { |key| key.split('_').last.to_i }
    work_days.include? Date.today.wday
  end

  def self.work_time?
    from = Time.parse Setting.plugin_redmine_intouch['work_day_from']
    to = Time.parse Setting.plugin_redmine_intouch['work_day_to']
    work_day? and from <= Time.now and Time.now <= to
  end

end
