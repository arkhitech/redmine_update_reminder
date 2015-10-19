class TelegramGroupChat < ActiveRecord::Base
  unloadable if Rails.env.production?
end
