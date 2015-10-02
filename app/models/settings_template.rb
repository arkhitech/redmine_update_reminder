class SettingsTemplate < ActiveRecord::Base
  unloadable

  attr_accessible :name, :settings

  store :settings, accessors: (%w(alarm new working feedback overdue).map do |notice|
    %w(author assigned_to watchers).map do |receiver|
      "telegram_#{notice}_#{receiver}".to_sym
    end << "telegram_#{notice}_telegram_groups".to_sym << "telegram_#{notice}_user_groups".to_sym
  end.flatten << :email_cc)


end
