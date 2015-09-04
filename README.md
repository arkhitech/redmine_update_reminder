# redmine_intouch

Плагин разработан [Centos-admin.ru](http://centos-admin.ru/).

Плагин предназначен для рассылки уведомлений пользователям RedMine и Telegram.
Состоит и двух модулей - email и telegram

## Telegram

Рассылает уведомления о сменене статуса задачи либо же напоминания о задачах, статус которых давно не менялся.

## E-mail

Отправляет уведомления исполнителям по задачам, в случае если задача не обновлялась больше, чем указанное в настройках количество часов.

Настройки указываются для каждого треккера индивидуальные.

### Настройка плагина

Перед запуском бота на странице настройки плагина нужно указать:

* токен бота Telegram (как его получить описано ниже)
* рабочее время - в это время отправляются уведомления по задачам с приорететам отличным от "Авария"
* указать какие приоритеты считать аварийными
* указать какие статусы считать новой задаче, в работе и обратной связью

После этого необходимо запустить бота командой:

```
bundle exec rake intouch:telegram:bot PID_DIR='/pid/dir'
```

Также необходимо добавить в CRON задачи описанные в `config/schedule.rb`.  Для этого нужно выполнить:

```
bundle exec whenever -w redmine_intouch -f plugins/redmine_intouch/config/schedule.rb
```

Очистить CRON от этих задач можно командой:

```
bundle exec whenever -c redmine_intouch -f plugins/redmine_intouch/config/schedule.rb
```

### Создание бота Telegram

Бота необходимо зарегистрировать и получить его токен. Для этого в Telegram существует специальный бот — @BotFather.

Пишем ему /start и получаем список всех его команд.
Первая и главная — /newbot — отправляем ему и бот просит придумать имя нашему новому боту. Единственное ограничение на имя — в конце оно должно оканчиваться на «bot». В случае успеха BotFather возвращает токен бота и ссылку для быстрого добавления бота в контакты, иначе придется поломать голову над именем.

Полученный токен нужно ввести на странце настройки плагина.

### Добавление аккаутна Telegram к пользователю

После того как бот запущен и пользователи поприветствовали его командой `/start`, 
на страничке редактированию пользователя, можно выбрать соответствующий ему аккаунт Telegram. 

### Настройка модуля внутри проекта

В настройках проекта на вкалдке "Модули" нужно выбрать модуль Intouch. 
В результате в настройках появится вкладка "Intouch".

На этой вкладке можно настроить по каким типам задач куда слать уведомления Telegram.

Типы задач:

* Авария
* Новая
* В работе
* Обратная связь
* Просроченная

Получатели уведомлений:

* Автор задачи
* Исполнитель
* Наблюдатели
* Группа пользователей RedMine
* Групповой чат Telegram

**Важное замечание: для того, чтобы пользователь Telegram получал сообщения, нужно чтобы он предварительно написал команду ```/start``` боту**

В разделе email можно указать кому посылать скрытую копию при отправке уведомлений по e-mail.

### Доступные rake-задачи

```rake intouch:email:send_reminders``` - отправляет увудомление исполнителям задач, которые давно не обновлялись

```rake intouch:telegram:bot PID_DIR='/pid/dir' LOG_DIR='/log/dir'``` - запускает процесс бота Telegram, параметры PID_DIR и LOG_DIR обязательны                              

```rake intouch:telegram:notification:alarm``` - отправляет уведомления пользователям Telegram об аварийных задачах             

```rake intouch:telegram:notification:feedback``` - отправляет уведомления пользователям Telegram о задачах с обратной связью          

```rake intouch:telegram:notification:new``` - отправляет уведомления пользователям Telegram о новых задачах               

```rake intouch:telegram:notification:overdue``` - отправляет уведомления пользователям Telegram о просроченных задачах           

```rake intouch:telegram:notification:work_in_progress```  - отправляет уведомления пользователям Telegram о задачах в статутсе "В работе"  

### Пример настройки schedule.rb

```ruby
every 1.hour do
  rake 'intouch:email:send_reminders'
end

every 30.minutes do
  rake 'intouch:telegram:notification:alarm'
end

every 1.day, at: '10:00' do
  rake 'intouch:telegram:notification:new'
  rake 'intouch:telegram:notification:overdue'
end

every 5.minutes do
  rake 'intouch:telegram:notification:work_in_progress'
end

every 5.minutes do
  rake 'intouch:telegram:notification:feedback'
end
```



Плагин разработан [Centos-admin.ru](http://centos-admin.ru/).
