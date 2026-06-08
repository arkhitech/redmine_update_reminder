require_dependency 'time_entry'

module TimeRestrictionPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      validate :spent_on_log_time_restriction
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    def spent_on_log_time_restriction
      unless User.current.admin
        errors.add(:spent_on, "can't be #{max_past_time_log_insert_days} days older in the past") if !spent_on.blank? && spent_on < (Date.today - max_past_time_log_insert_days.days)
        errors.add(:spent_on, "can't be in future") if !spent_on.blank? && spent_on > Date.today
        errors.add(:spent_on, "can't be in future") if !spent_on.blank? && spent_on > Date.today
        errors.add(:hours, "is more than max working hours (#{max_working_hours}) for the day") if hours.to_f > max_working_hours
      end
    end

    def max_working_hours
      (Setting.plugin_redmine_update_reminder['max_working_hours'] || 15).to_f      
    end
    private :max_working_hours

    def max_past_time_log_insert_days
      @max_past_time_log_insert_days ||= 45
      #(Setting.plugin_redmine_update_reminder['max_past_timelog_insert_days'] || 7).to_f
    end
    private :max_past_time_log_insert_days
  end
end

# Add module to TimeEntry
TimeEntry.send(:include, TimeRestrictionPatch)
