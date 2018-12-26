# frozen_string_literal: true

namespace :intouch do
  desc 'Fix settings for Rails 5 compatibility'
  task fix_settings: :environment do
    if Rails.version < '5.0'
      puts "You don't need to run this task on Rails versions prior to 5.0"
      next
    end

    ActiveRecord::Base.connection.execute(
      <<~SQL.squish
        UPDATE 
          settings_templates 
        SET 
          intouch_settings = replace(
            intouch_settings, 'ActionController::Parameters', 
            'ActiveSupport::HashWithIndifferentAccess'
          );
        UPDATE 
          projects 
        SET 
          intouch_settings = replace(
            intouch_settings, 'ActionController::Parameters', 
            'ActiveSupport::HashWithIndifferentAccess'
          );
      SQL
    )

    puts 'Intouch settings have been fixed'
  end
end
