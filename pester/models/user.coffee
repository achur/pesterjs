redis = require('redis')
base = require('./base')
_ = require('underscore')

# A simple user class
class User extends base.BaseModel
  # Enumerate the properties we want each user object to get back from
  # Facebook. These, in combination with the user's phone number and some
  # additional properties make up a user object.
  #
  # We implicitly use the fbid for our id nomenclature.
  #
  # Note you can modify these as much as you want. Here, I'm just playing
  # with pulling some basic data down from Facebook.
  @_user_facebook_properties: [
    'name'
    'username'
    'gender'
    'email'
  ]

  @_additional_save_properties: [
    'id'
    'number'
    'active_notifications'
    'completed_notifications'
    'last_done'
    'snooze_until'
  ]

  _properties: @_user_facebook_properties.concat @_additional_save_properties

  update: (profile) =>
    if not profile? then return
    for prop in @constructor._user_facebook_properties
      if profile[prop]?
        @[prop] = profile[prop]
    @active_notifications ?= []
    @completed_notifications ?= []

  handle_done: (time) =>
    for note in @active_notifications
      if note.last_notified?
        @completed_notifications.unshift(note)
    while @completed_notifications.length > 20
      @completed_notifications.pop()
    @active_notifications = _.filter @active_notifications, (note) -> !note.last_notified
    now = new Date()
    time ?= now.getTime()
    @last_done = time

  handle_snooze: (time, minutes) =>
    millis = minutes * 60 * 1000
    newsnooze = time.getTime() + millis
    if not @snooze_until? or @snooze_until < newsnooze
      @snooze_until = newsnooze

  notify: (str) =>
    note =
      text: str
      activations: 1
      last_notified: null
      period: -1
    @active_notifications.unshift(note)

  save: (args...) =>
    super(args...)
    @constructor._rclient.sadd('user', @id)

  @load_users: ->
    @_rclient.smembers 'user', (err, reply) =>
      for id in reply
        @get_or_create id

  @get_by_number: (number) ->
    for id, user of @_store
      if user.number == number
        return user
    null

exports.User = User
