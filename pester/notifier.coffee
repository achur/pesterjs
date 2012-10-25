# This file starts a notification loop
# that texts the users

User = require('./models/user').User
variables = require('./variables')

google_voice = require('google-voice')
GV = new google_voice.Client(email: variables.GV_EMAIL, password: variables.GV_PASSWORD)

send_notify = (user, notification) ->
  GV.connect('sms', {outgoingNumber: user.number, text: notification.text})

process_notify = (user, notification) ->
  if not user.number? then return
  now = new Date()
  # We don't notify the user if they are snoozing
  if user.snooze_until? and user.snooze_until > now.getTime() then return
  now = new Date()
  if not notification.last_notified? or now - notification.last_notified > notification.period
    notification.last_notified = now
    if notification.period < 0
      notification.period = variables.MAX_PERIOD
    new_period = notification.period * 0.75
    if new_period < variables.MIN_PERIOD then new_period = variables.MIN_PERIOD
    notification.period = new_period
    send_notify(user, notification)
    user.save()

check_sms = ->
  GV.get 'sms', {limit: 20}, (e, resp) ->
    messages = resp.messages
    for message in messages
      for item in message.thread
        res = item.from.match(/\+1(\d+)/)
        justtext = item.text.toLowerCase().replace(/[^a-z]/g, "")
        if res?
          number = res[1]
          user = User.get_by_number(number)
          if user?
            time = Date.create(item.time)
            if justtext == 'done'
              # Give a 2 minute cushion to deal with system time difference
              if not user.last_done or user.last_done < time.getTime() + 120000
                user.handle_done(time.getTime() + 120000)
                console.log 'Done -->'
                console.log user
                user.save()
            if justtext == 'snooze'
              # See if they tell us how long to snooze. Otherwise, do an hour.
              altext = item.text.toLowerCase().replace(/\W/g, "")
              match = altext.match(/snooze(\d+)/)
              if match?
                minutes = Number(match[1])
              else
                minutes = 60
              user.handle_snooze(time, minutes)

process_all = ->
  for id, user of User._store
    for notification in user.active_notifications
      process_notify(user, notification)
  check_sms()

# Do a run-through every 60 seconds
setInterval(process_all, 60000)

