# redmine_intouch

Plugin is designed by [Centos-admin.ru](http://centos-admin.ru/).

Plugin is designed to send notifications to Redmine’s users by Telegram or E-mail.

## Requirements

**Redmine 3.1.x**

This plugin relies on the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin.

[Launch Sidekiq as daemon](https://github.com/mperham/sidekiq/wiki/Deployment#daemonization)

* The `tools` folder has the examples of the plugin config files and the `init.d` startup script

# Plugin Setup

## General settings

You should specify all the necessary notification protocols in the "Protocols" section. These are 'telegram' and 'email' available at the moment.

The section "Working days" should contain: 

* when the workday starts and when it ends
* what days are considered as workdays

The section "Urgent Tasks" contains the ticket priorities, that will have notifications being sent despite of the time or day of a week.

The plugin contains the fuctionality that allows you send scheduled notifications tagged as "In work" or "Feedback". Specify these statuses in appropriate sections so the plugin could parse them correctly.

## Telegram

On this tab, you must specify the Telegram bot token.

### Creating a Telegram bot

It is necessary to register a bot and get its token. For this purpose, there is a special bot in Telegram - @BotFather.

We should write for him `/start` and get a list of all its commands.
The first and foremost - `/newbot`  - we send to it and the bot asks to come up with the name for our new bot.
The only restriction on the name - it must be ended with “bot”.
If successful, @BotFather returns a bot token and link to quickly add a bot to contacts;
otherwise you'll have to break your head over the name.

The resulting token must be entered in the plugin settings page.

### Bot launch

Before launching the bot, you must specify in the plugin settings page:

* Telegram’s bot token (how to get it is described below)
* working time - notifications about non-urgent issues are sent during this time
* specify what priorities should be considered as urgent ones
* specify what statuses should be considered _in work_ and _feedback_

After that you need to launch a bot by command:

```shell
bundle exec rake intouch:telegram:bot PID_DIR='/pid/dir'
```

Example of the script for `init.d` in the `tools` folder.

This process adds Telegram’s users in Redmine, as well as creates the Telegram groups in Redmine,
in which the bot was added.

### Adding a Telegram account to the user

Once the bot was launched and the user welcomed it by `/start` command,
it is possible to select the corresponding Telegram account for the user on the user’s editing page.

#### If the bot has been changed

If you have changed the bot, then each user needs to greet it personally.

That is, to find @YourTelegramBot through the search and to write to it `/start`.

### Adding a Telegram Group

The groups will be added automatically in Redmine, if the boat will be added to them.

The name of the group is saved right away when adding.
If some time later you change the name of the group and want to update the name in Redmine,
perform the command `/rename` in the group chat.

## Setting Templates

Setting templates allow you to specify all the required settings for the project only one time
and then to select the desired template in each project.
Read below for more information on the plugin settings within the project.


## Regular Notifications Schedule

The plugin is provided with:

* Notification about issues with the status "In work"
* Notification about issues with the status "Feedback"
* Notifications about unassigned issues
* Notifications about overdue issues

The frequency and recipients of these notifications are set for each project individually or using templates.

Regular notifications schedule regular is set on the plugin settings page, on the **Periodic tasks schedule** tab.

When you set the plugin for the first time, you need to initialize the periodic tasks.

You can then set a periodic notifications schedule convenient to you.

Schedule is set using the CRON syntax.

It is important to note that on this tab you should set how often to check for availability of issues on which
you want to send the notifications.
The frequency of the notifications themselves is indicated in each project individually or using templates.

# Setting the module within the project

You must select the Intouch module in the project settings on the "Modules" tab.
As a result, the "Intouch" tab appears in the settings.

This tab includes three sections:

* Instant notifications when changing the issue status/priority
* Periodic notifications
* Assigner groups

## Instant notifications when changing the issue status/priority

In this section, instant notifications are set for the following recipients:

* Author
* Assigner
* Task watchers
* Telegram groups

**Important note: In order that the Telegram’s user can receive messages,
the user must preliminarily write the `/start` command to the bot**

## Periodic notifications

### General settings

The intervals of periodic notifications for different priorities are specified in general settings.

### In work / Feedback

The recipients of periodic notifications about the issues with the statuses
"In work" and "Feedback" are specified on these tabs.

### Unassigned / Assigned to the group

On this tab, one should specify recipients of periodic notifications about the issues

* without the designated assigner
* assigned to the group

### Overdue / Without a due date

On this tab, one should specify recipients of periodic notifications about the issues

* the due date of which is in the past
* with an unspecified due date

# Author of the Plugin

The plugin is designed by [Centos-admin.ru](http://centos-admin.ru/).
