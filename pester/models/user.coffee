redis = require('redis')
base = require('./base')

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
  ]

  _properties: @_user_facebook_properties.concat @_additional_save_properties

  update: (profile) =>
    if not profile? then return
    for prop in @constructor._user_facebook_properties
      if profile[prop]?
        @[prop] = profile[prop]

exports.User = User
