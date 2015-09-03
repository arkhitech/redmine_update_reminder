class TelegramUser < ActiveRecord::Base
  unloadable

  belongs_to :user
end
