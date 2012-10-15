express = require('express')
app = express()

zappajs ->
  @use 'static': __dirname + '/static'
  @get
    '/': (req, resp) ->
      console.log req
      console.log resp
      'hi'
