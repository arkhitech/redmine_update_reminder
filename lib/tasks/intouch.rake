namespace :intouch do
  namespace :common do
    # bundle exec rake intouch:common:migrate
    task migrate: :environment do
      TelegramUser.find_each do |telegram_user|
        TelegramCommon::Account.where(telegram_id: telegram_user.tid)
          .first_or_create(telegram_user.slice(:user_id, :first_name, :last_name, :username, :active))
      end
    end
  end
end
