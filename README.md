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

Specify the Telegram Bot token here.

### Creating a Telegram bot

It is necessary to register a bot and get its token. There is a special bot in Telegram for this purpose. It is called @BotFather.

Start it by typing `/start` to get a list of all available commands.
Issue the  `/newbot` command and it will ask you to come up with the name for our new bot.
The name must end with "bot" word.
On success @BotFather will give you token for your new bot and a link to quickly add the bot to contact list.
You'll have to invent a new name if the registration fails.

You should enter the token you've just created on the Plugin Settings page.

### Bot launch

Specify the following things before launching the bot:

* The Telegram bot token (create a new one as described above if you haven't done it already)
* Working Time - when and what notifications will be sent
* Specify what priorities should be considered as urgent ones
* Specify what statuses should be considered _in work_ and _feedback_

Run the bot after that by typing:

```shell
bundle exec rake intouch:telegram:bot PID_DIR='/pid/dir'
```

The `tools` folder has the examples of the plugin config files and the `init.d` startup script.

This will add the Telegram users to Redmine and create the Telegram groups in which it was added in Redmine.

### Adding a Telegram account to the user

It is also possible to choose the corresponding account for users added with the `/start` command on the user details page.

#### If the bot has been changed

If you have changed the bot, then each user needs to greet it personally.
One has to connect to the new bot if it has been changed. To do that all the participating Users should find the new bot via search and type the `/start` command again.

### Adding a Telegram Group

The groups are added to Redmine, if the bot was added to them.

The group name is saved on addition. Issue the `/rename` command in the group chat to change the group name in Redmine.

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

One has to initialize the priodic tasks before the plugin's first run.

You can also set periodic notifications schedule convenient to you.

Schedule is set using the cron syntax.

# Setting the module within the project

You must select the Intouch module in the project settings on the "Modules" tab.
As a result, the "Intouch" tab in the settings will appear.

This tab includes three sections:

* Instant notifications when changing the issue status/priority
* Periodic notifications
* Assigner groups

## Instant notifications when changing the issue status/priority

This section lets you set instant notifications for the following recipients:

* Author
* Assigner
* Task watchers
* Telegram groups

**Important note: The Telegram user should issue the `/start` command to recieve messages.

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
