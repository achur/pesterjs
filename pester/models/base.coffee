redis = require('redis')
_ = require('underscore')

# A simple model class in the backbone.js style, but stripped down
# and designed to connect to redis
class BaseModel
  # A private redis client for use by the User class -- singleton
  @_rclient: redis.createClient()

  # A private singleton store for current User objects, keyed by id.
  @_store: {}

  constructor: (options) ->
    if not options?.id?
      throw new Error("A model needs an id!")
    @id = options.id
    @storeModel(@)

  storeModel: (model) =>
    @constructor._store[model.id] = model

  set: (dict) ->
    for k, v of dict
      @[k] = v

  # Save the model to the Redis store. callback is an optional function
  # that, if present, gets called by the redis client.
  #
  # This saves only the elements declared in @_properties (which should
  # be handled by subclasses).
  save: (callback) ->
    klass = @constructor.name
    if not @id?
      throw new Error("#{ klass } object has no id so can't be saved")
    key = "#{ klass }:#{ @id }"
    if not @_properties?
      throw new Error("You need to define @_properties for #{ klass } before saving")
    dict = {}
    for prop in @_properties
      val = @[prop] ? null
      dict[prop] = val
    value = JSON.stringify(dict)
    @constructor._rclient.set(key, value, callback)

  # Loads the latest data from redis and populates the current model.
  #
  # callback(found): called back after population. found is true if we
  # actually found the model in redis
  load: (callback) =>
    klass = @constructor.name
    if not @id?
      throw new Error("#{ klass } object has no id so can't be loaded")
    key = "#{ klass }:#{ @id }"
    if not @_properties?
      throw new Error("You need to define @_properties for #{ klass } before saving")
    @constructor._rclient.get key, (err, reply) =>
      if reply?
        resp = JSON.parse(reply)
        for k, v of resp
          if _.indexOf(@_properties, k) >= 0
            @[k] = v
        callback(true)
      else
        callback(false)

  # Function: get_or_create(id, [options], callback)
  #
  # Gets a model from the store or database, creating a new one
  # if the model doesn't already exist
  #
  # - id: the id of the model
  # - options: a dictionary. If the function `update` exists, update(options)
  # will be called at the conclusion of this method.
  # - callback: (model, created, cached) ->: A callback function which is
  # called with the appropriate model. created is a boolean representing whether
  # the model had to be created. cached is true if the model was retrieved
  # from the store.
  #
  # This DOES NOT save the model, so if you want to persist it in the database,
  # you MUST call save on it.
  @get_or_create: (id, options, callback) ->
    if @_store[id]
      model = @_store[id]
      if model.update?
        model.update(options)
      callback?(model, false, true)
    else
      model = new @(id: id)
      model.load (found) ->
        if model.update?
          model.update(options)
        callback?(model, !found, false)

exports.BaseModel = BaseModel
