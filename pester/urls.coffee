define ->
  'get':
    '/': (req, res) ->
      req.session.count ?= 0
      console.log req.session.count++
      console.log req.user
      res.render 'base'

