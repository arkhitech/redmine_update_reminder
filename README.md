# redmine_intouch

This plugin sends reminder email to assigned users if an issue is not updated within specified duration.
Developed by: [Centos-admin.ru](http://centos-admin.ru/)

## Настройка бота Telegram

Бота необходимо зарегистрировать и получить его токен. Для этого в Telegram существует специальный бот — @BotFather.

Пишем ему /start и получаем список всех его команд.
Первая и главная — /newbot — отправляем ему и бот просит придумать имя нашему новому боту. Единственное ограничение на имя — в конце оно должно оканчиваться на «bot». В случае успеха BotFather возвращает токен бота и ссылку для быстрого добавления бота в контакты, иначе придется поломать голову над именем.

Полученный токен нужно ввести на странце настройки плагина.

После этого можно запустить бота командой:

```
bundle exec rake intouch:telegram:bot PID_DIR='/pid/dir' LOG_DIR='/log/dir' &
```

Functionality:
==============

All the mails are CC'ed to a single User (generally scrum master) along with the assigned user for notifying that a given task needs updation.
The duration for each kind of tracker can be set in settings.
Duration takes input in days, and can be decimal point numbers (for instance .5 for 12 hours).
Emails Headers and Footers are configurable for personalization.

Installation:
=============

The plugin is available for download from
	`github.com:olemskoi/redmine_intouch`

Go to redmine's plugins directory and `wheneverize` the downloaded redmine_intouch plugin directory.
Open config directory and edit schedule.rb


for example:

	set :environment, "production"
	every 15.minutes do
	rake "redmine_intouch:send_reminders"
	end

This will check for all issues that have not been updated in the specified duration from current time and send them an email.
These issues will be checked every 15 minutes and will be sent emails till they are updated.

Check whenever gems documentation for detailed description of its working.

The rake task can be run without scheduling using this command
rake redmine_update_reminder:send_reminders
