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
