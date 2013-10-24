Redmine_Update_Reminder:
========================

This plugin sends reminder email to assigned users if an issue is not updated within specified duration.

Functionality:
==============

All the mails are CC'ed to a single User (generally scrum master) along with the assigned user for notifying that a given task needs updation.  
The duration for each kind of tracker can be set in settings.
Duration takes input in days, and can be decimal point numbers (for instance .5 for 12 hours).
Emails Headers and Footers are configurable for personalization.

Installation:
=============

The plugin is available for download from 
	`github.com:arkhitech/redmine_update_reminder`

Go to redmine's plugins directory and `wheneverize` the downloaded redmine_update_reminder plugin directory.
Open config directory and edit schedule.rb


for example:

	set :environment, "production"
	every 15.minutes do
	rake "redmine_update_reminder:send_reminders"
	end 

This will check for all issues that have not been updated in the specified duration from current time and send them an email. 
These issues will be checked every 15 minutes and will be sent emails till they are updated. 

Check whenever gems documentation for detailed description of its working.

The rake task can be run without scheduling using this command
rake redmine_update_reminder:send_reminders

