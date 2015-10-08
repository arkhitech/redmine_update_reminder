module Intouch
  module UserPatch
    def self.included(base) # :nodoc:

      base.class_eval do
        unloadable if Rails.env.production?

        has_one :telegram_user, dependent: :destroy

        safe_attributes 'telegram_user_id'

        def telegram_user_id
          telegram_user.try :id
        end

        def telegram_user_id=(id)
          self.telegram_user = TelegramUser.find(id) if id.present?
        end
      end
    end

  end
end
User.send(:include, Intouch::UserPatch)
