# 1.0.1

* Add Rails 5.1 support
* Fix uninitialized constant TelegramMessageSender::Telegram
* Remove git usage in plugin code
* Fix LiveHandlerWorker not found issue
* Fix mail from field

# 1.0.0

* Upgrade redmine_telegram_common to version 0.1.0 
* Move from telegrammer to telegram-bot-ruby
* Telegram bot can work via getUpdates or WebHooks
* Telegram rake bot will bind default to tmp/pids

# 0.6.2

* Add support sidekiq 5 version

# 0.6.1

* Fix regular recipients list, add logging to regular group sender worker

# 0.6.0

* Regular and live message refactoring and tuning
* Fix issues [#33](https://github.com/centosadmin/redmine_intouch/issues/33) and [#43](https://github.com/centosadmin/redmine_intouch/issues/43)

# 0.5.3

* Fix: Always send live message for required recipients for settings template

# 0.5.2

* `without_due_date?` regression hot fix

# 0.5.1

* Extract regular notification text to service class

# 0.5.0

* New feature: Always send live message for required recipients

# 0.4.1

* Fix projects helper patch

# 0.4.0

* Update for use [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common) version 0.0.12

# 0.3.3

* Add help command

# 0.3.1

* Add exception notification on bot restart

# 0.3.0

Migrate to [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common) plugin.
* before upgrade please install [this](https://github.com/centosadmin/redmine_telegram_common) plugin.
* run `bundle exec rake intouch:common:migrate` after upgrade

# 0.2.0
* Add checkboxes for select all priorities and statuses
* Add copy settings template feature
