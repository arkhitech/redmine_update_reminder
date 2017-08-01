[Русская версия](README-RU.md)

# redmine_intouch

[![Code Climate](https://codeclimate.com/github/centosadmin/redmine_intouch/badges/gpa.svg)](https://codeclimate.com/github/centosadmin/redmine_intouch)
[![Build Status](https://travis-ci.org/centosadmin/redmine_intouch.svg?branch=master)](https://travis-ci.org/centosadmin/redmine_intouch)

Plugin is designed to send notifications to Redmine’s users by Telegram or E-mail.

Please help us make this plugin better telling us of any [issues](https://github.com/centosadmin/redmine_intouch/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.

# Installation

## Requirements

* **Ruby 2.3+**
* **Redmine 3.1+**
* Configured [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
* You should have Telegram bot account
* Install [Redis](https://redis.io) 2.8 or higher. Run Redis and add it to autorun.
* Install the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin. [Redis](https://redis.io) 2.8 or greater is required.
* You need to configure Sidekiq queues `default` and `telegram`. [Config example](https://github.com/centosadmin/redmine_intouch/blob/master/extras/sidekiq.yml) - place it to `redmine/config` directory (Or copy from plugins/redmine_intouch/extras/sidekiq.yml to config/sidekiq.yml).
* Standard install plugin:

```
cd {REDMINE_ROOT}
git clone https://github.com/centosadmin/redmine_intouch.git plugins/redmine_intouch
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

The `extras` folder has the examples of the plugin config files and the `init.d` startup script

### Upgrade from 0.3 to 1.0.0+
 
Since version 1.0.0 this plugin uses [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
0.1.0 version, where removed Telegram CLI dependency. Please, take a look on new requirements.

### Upgrade from 0.2 to 0.3+

Since version 0.2 this plugin uses [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
plugin.

Before upgrade install [this](https://github.com/centosadmin/redmine_telegram_common) plugin.

Then upgrade and run `bundle exec rake intouch:common:migrate RAILS_ENV=production` for migrate data to new table.

Since 0.4 version, model `TelegramUser` will be removed, also table `telegram_users` will be removed.

# Plugin Setup

## General settings

You should specify all the necessary notification protocols in the "Protocols" section. These are 'telegram' and 'email' available at the moment.

The section "Working days" should contain:

* when the workday starts and when it ends
* what days are considered as workdays

The section "Urgent Tasks" contains the ticket priorities, that will have notifications being sent despite of the time or day of a week.

The plugin contains the fuctionality that allows you to send scheduled notifications tagged as "In work" or "Feedback". Specify these statuses in appropriate sections so the plugin could parse them correctly.

## Telegram

Specify the Telegram Bot token here, save settings and then initialize bot.

### Creating a Telegram bot

It is necessary to register a bot and get its token. There is a special bot in Telegram for this purpose. It is called @BotFather.

Start it by typing `/start` to get a list of all available commands.
Issue the  `/newbot` command and it will ask you to come up with the name for our new bot.
The name must end with "bot" word.
On success @BotFather will give you a token for your new bot and a link so you could quickly add the bot to contact list.
You'll have to invent a new name if the registration fails.

You should enter the token you've just created on the Plugin Settings page.

### Bot modes 

Bot can work in two [modes](https://core.telegram.org/bots/api#getting-updates) — getUpdates or WebHooks.
 
#### getUpdates

To work via getUpdates, you should run bot process `bundle exec rake intouch:telegram:bot`. 
This will drop bot WebHook setting.

#### WebHooks

To work via WebHooks, you should go to plugin settings and press button "Initialize bot" 
(bot token should be saved earlier, and notice redmine should work on https)

### Bot launch

Specify the following things before launching the bot:

* The Telegram bot token (create a new one as described above if you haven't done it already)
* Working Time - when and what notifications will be sent
* Specify what priorities should be considered as urgent ones
* Specify what statuses should be considered _in work_ and _feedback_
* Save settings

### Adding a Telegram account to the user

User needs to add a bot with `/start` command.

After that the bot prompts to enter the command `/connect account@redmine.com`.

After the command, the user will receive an email with a link.

Following the link will connect the user's accounts.

#### If the bot has been changed

If you have changed the bot, then each user needs to greet it personally.
One has to connect to the new bot if it has been changed. To do that all the participating Users should find the new bot via search and type the `/start` command again.

### Adding a Telegram Group

The groups are added to Redmine, if the bot was added to them.

The group name is saved on addition. Issue the `/rename` command in the group chat to change the group name in Redmine.

### Available commands

- `/help` - list of available commands with its descriptions

**Private chat with bot**

- `/connect e@mail.com` - connect Telegram and Redmine accounts
- `/update` - update Telegram account info (after change name or username)

**Group chat**

- `/update` - update group name (after change Telegram group name)

#### Hints for bot commands

Use command `/setcommands` with [@BotFather](https://telegram.me/botfather). Send this list for setup hints:

```
start - Start work with bot
connect - Connect Redmine and Telegram account
update - Update Telegram account info or group name
help - Help about commands
```

## Settings Templates

The settings templates allow you to set all the required project settings once, and then just choose the right template for each project.
Read below of the settings of the plugin integrated into the project.

## Regular Notifications Schedule

The plugin is provided with:

* Notification about issues with the "In work" status;
* Notification about issues with the "Feedback" status;
* Notifications about unassigned issues;
* Notifications about overdue issues.

The periodicity of the repeating messages and the recipients settings are configured separately for each project or with templates.
The regular notifications schedule is set on the **Periodic tasks schedule** tab located on the Plugin Settings page.

One has to initialize the periodic tasks before the plugin's first run.

To do this, click "Initialize periodic tasks" in the "Schedule periodic tasks" tab in the plugin settings.

You can also set periodic notifications schedule convenient for you.

Schedule is set using the cron syntax.

# Setting the module within the project

Select the Intouch module in the project settings on the "Modules" tab.
As a result, the "Intouch" tab will appear in the Settings.

This tab includes three sections:

* Instant notifications when changing the issue status/priority
* Periodic notifications
* Assigner groups

## Instant notifications when changing the issue status/priority

This section allows you to set instant notifications for the following recipients:

* Author
* Assigner
* Task watchers
* Telegram groups

**Important note: The Telegram user should issue the `/start` command to recieve messages.**

## Periodic notifications

### General settings

The intervals of Periodic Notifications for different priority types are specified in General Settings.

### In work / Feedback

These tabs contain recipients of the Periodic Notifications with the "In work" and "Feedback" statuses.

### Unassigned / Assigned to the group

This tab contains recipients of the Periodic Notifications that are:

* not assigned to anyone
* assigned to the group

### Overdue / Without a due date

This tab contains recipients of the Periodic Notifications that are:

* overdue
* with unspecified due date

# FAQ
## Why does not the bot send messages to a group chat?

Perhaps you have not initialized **Periodic tasks schedule**.

In plugin settings go to the **Periodic tasks schedule** tab and click **Initialize periodic tasks**.


# Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
