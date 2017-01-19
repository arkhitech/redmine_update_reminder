class TelegramUser < ActiveRecord::Base
  unloadable

  belongs_to :user
  attr_accessible :tid, :user_id, :first_name, :last_name, :username, :active

  def name
    if username.present?
      "#{first_name} #{last_name} @#{username}"
    else
      "#{first_name} #{last_name}"
    end
  end

  def activate!
    update(active: true) unless active?
  end

  def deactivate!
    update(active: false) if active?
  end
end
