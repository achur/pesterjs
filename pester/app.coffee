# Allow AMD packages (which are better/more flexible than CommonJS)
require("amd-loader")

# Require and setup
express = require('express')
app = express()

# Hook up router and middleware
app.configure ->
  app.use(app.router)
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

# Hook up static files under the static subdirectory
stat = express.static(__dirname + '/static/')
app.get /^\/static\/(.+$)/, (req, res, next) ->
  req.url = req.params[0]
  stat(req, res, next)

routes = require('./urls.coffee')
for url of routes
  app.get url, routes[url]

app.listen 3000
