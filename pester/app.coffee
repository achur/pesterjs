# Allow AMD packages (which are better/more flexible than CommonJS)
require('amd-loader')

# Private variables
variables = require('./variables')

# Require and setup
express = require('express')
app = express()
RedisStore = require('connect-redis')(express)
User = require('./models/user').User

# Prepare auth thru passport
passport = require('passport')
FacebookStrategy = require('passport-facebook').Strategy
passport.use new FacebookStrategy
  clientID: variables.FACEBOOK_APP_ID
  clientSecret: variables.FACEBOOK_APP_SECRET
  callbackURL: variables.SITE_URL + '/auth/facebook/callback'
  (accessToken, refreshToken, profile, done) ->
    User.get_or_create profile.id, profile, (user, created, cached) ->
      # Always save the user with fresh info from facebook
      user.save()
      if created
        console.log "CREATED A USER"
      done(null, user)
passport.serializeUser (user, done) ->
  done(null, user.id)
passport.deserializeUser (id, done) ->
  User.get_or_create id, null, (user, created, cached) ->
    done(null, user)

# Hook up router and middleware
app.configure ->
  app.use(express.cookieParser())
  app.use(express.cookieSession(secret: variables.SESSION_SECRET, store: new RedisStore))
  app.use(passport.initialize())
  app.use(passport.session())
  app.use(app.router)
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

# Auth callbacks
app.get '/auth/facebook', passport.authenticate('facebook')
app.get '/auth/facebook/callback',
  passport.authenticate('facebook', { successRedirect: '/', failureRedirect: '/login' })


# Hook up static files under the static subdirectory
stat = express.static(__dirname + '/static/')
app.get /^\/static\/(.+$)/, (req, res, next) ->
  req.url = req.params[0]
  stat(req, res, next)

# Hook up urls.coffee to the routes
routes = require('./urls')
for url of routes.get
  app.get url, routes.get[url]
for url of routes.post
  app.post url, routes.post[url]

app.listen 3000
