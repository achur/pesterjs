utils = require('./utilities')
User = require('./models/user').User
require('sugar')

define ->
  'get':
    '/': (req, res) ->
      if req.user? # serve up static site
        req.session.count ?= 0
        console.log req.session.count++
        console.log req.user
        if req.user.number?
          res.render 'home',
            user: req.user
            utils: utils
        else
          res.redirect '/number/'
      else
        res.redirect '/preview/'
    '/login/': (req, res) -> res.redirect '/auth/facebook/'
    '/preview/': (req, res) ->
      res.render 'preview',
        user: req.user
    '/number/': (req, res) ->
      res.render 'number',
        user: req.user
    '/notify/': (req, res) ->
      res.render 'notify'
        users: User._store
    '/done/': (req, res) ->
      if req.user?
        req.user.handle_done()
        req.user.save()
      res.redirect('/')
  'post':
    '/update/': (req, res) ->
      if req.user? and req.body?.phonenumber?
        req.user.number = req.body.phonenumber
        req.user.save()
      res.redirect '/'
    '/send/': (req, res) ->
      id = req.body.user
      text = req.body.text
      User.get_or_create id, null, (user, created, cached) ->
        if user? and not created
          user.notify(text)
          user.save()
        res.redirect '/'


