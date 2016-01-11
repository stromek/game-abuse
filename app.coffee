
# Module dependencies.

GAME = require('./server/game.coffee')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')
fs = require('fs')

logFile = fs.createWriteStream('./log/access.log', {flags: 'a'}) #use {flags: 'w'} to open in write mode


app = express()


# all environments
app.use(express.logger({stream: logFile}))
# app.use(express.logger('dev'))

app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.cookieParser('your secret here'))
app.use(express.session())
app.use(app.router)

app.use(require('stylus').middleware(__dirname + '/public'))
app.use(express.static(path.join(__dirname, 'public')))

# development only
if 'development' is app.get('env')
  app.use(express.errorHandler())

app.get('/', routes.index)
app.get('/users', user.list)

httpServer = http.createServer(app).listen app.get('port'), () ->
  console.log('Express server listening on port ' + app.get('port'))

io = require('socket.io').listen(httpServer)
io.set('log level', 1)


server = new GAME.Server
map = new GAME.Map
map.load(1)

server.setMap(map)
server.setSocket(io)
server.run()
# server
