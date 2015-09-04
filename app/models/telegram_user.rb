class TelegramUser < ActiveRecord::Base
  unloadable

  belongs_to :user

  def name
    if username.present?
      "#{first_name} #{last_name} @#{username}"
    else
      "#{first_name} #{last_name}"
    end
  end
end
