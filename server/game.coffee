require('colors')
_ = require('underscore')

# Quadtree = require("./giant-quadtree/quadtree.js").Quadtree
# Quadtree = require("./QuadTree.js")
Quadtree = require("./space.connector.coffee")

Node = require('./node.coffee')
Map = require('./map.coffee')
User = require('./user.coffee')
util = require('util')

class Server
  constructor : () ->
    @users = {}
    @usersID = 0
    # Objekty (vse)
    @nodes = []
    # Objekty ktere potrebuji volat turn()
    @nodesTurn = [] 
    @fps = 120
    @delta = 1 / @fps

    ###
     FPS
    ###
    @fpsLastTime = process.hrtime()
    @fpsIndex = 0
    @fpsList = [@fpsLastTime]


    console.log "DELTA:", @delta

    @fpsSocket = 120
    @tree = null
    @stat = {
      nodeDisabled : 0
    }

  setMap : ( @map ) ->
    opt = {
      x: 0
      y: 0
      width: @map.getWidth()
      height: @map.getHeight()
    }

    @tree = new Quadtree(opt)

    for node in @map.getNodes()
      @addNode node

    return @

  getMap : ( ) -> @map

  getUser : ( user_id ) -> @users[user_id]


  remNode : ( id ) ->
    id = parseInt id, 10

    console.log "game > remNode ##{id}"
    
    tmp = ( node ) =>
      if node.getID() is id
        @stat.nodeDisabled++
        node.setDisabled(true)
        return false

      return true

    @nodes = _.filter @nodes, tmp
    @nodesTurn = _.filter @nodesTurn, tmp


    @io.sockets.emit 'remNode', id


  addNode : ( node ) ->
    @tree.insert(node.getX(), node.getY(), node.getWidth(), node.getHeight(), {node})
    node.setServer this
    @nodes.push node

    if node.isTurn()
      @nodesTurn.push node

    @emit 'status'

    # switch node.getType().toLowerCase()
    #    when "player"
    #      console.log "hrac"
       
      


  setSocket : ( @io ) ->
    @io.sockets.on 'connection', @addUser


  remUser : ( user_id ) =>
    user = @getUser user_id
    user.destroy()
    delete @users[user_id]

    console.log "User disconnect: ##{user_id}".red

  addUser : (socket) =>
    id = @usersID++

    user = new User()
    user.setServer this
    user.setSocket socket
    user.setID id

    
    socket.on 'keys', (data) =>
      user.setKeys data

    socket.on 'disconnect', () =>
      @remUser id


    
    # user.send 'map', @map.getClientData()
    # user.send 'status', @getStatus()
    # user.send 'nodes', @getNodesClientData()
    @users[id] = user
    startPosition = @map.getStartPosition(user)    

    @emit 'map', user
    @emit 'nodes', user

    user.init(startPosition)
    
    @emit 'status'
    @emit 'userstatus', user

    console.log "New disconnect: ##{id}".green


  emit : (name, users = false) =>
    res = null
    switch name
      when 'map'
        res = (user_id) =>
          # return {width : 800, height : 600}
          return @map.getClientData()

      when 'status'
        res = () =>
          return @getStatus()


      when 'viewPort'
        res = (user_id) =>
          user = @getUser(user_id)

          return user.getViewPort()

      when 'userstatus'
        res = () ->
          return {
            id : users.getID()
            nodes : {
              player : users.getNodeID()
            }
          }

      when 'nodes'
        res = (user_id) =>
          user = @getUser(user_id)

          view = user.getViewPort(true)
          x = user.getViewPort(true)
          # console.log(view)
          view.x = Math.max(view.x, 0)
          view.y = Math.max(view.y, 0)
          # view.width = Math.min(@map.width - view.width, view.x + view.width)
          # view.height = Math.min(@map.height - view.height, view.y + view.height)

          return @getNodesClientData(view.x, view.y, view.width, view.height)

    if res is null
      return false

    if typeof(res) isnt 'function'
      res = do(res) ->
        ( user_id ) ->
          return res

    # neprisel zadny uzivatel
    if users is false
      try
        # console.log "Seding #{name}"
        for id, user of @users
          if user and user.send and res
            user.send name, res(id)
          else
            console.log "user not exist !", id
      catch e
        console.log name, id, 'Chyba coffee ! RES neni funkce !'

    else if users and users.send and res
      # v users nam prisel jeden uzivatel
      users.send name, res(users.getID())
    else
      console.log "Neznam res() ?"

    return @

  getNodes : (x, y, width, height) ->
    k = 10
    for element in @tree.search(x - k, y - k, width + k, height + k)
      element[4].node

  getNodesClientData : (x, y, width, height) ->
    r = []
    for node in @getNodes(x, y, width, height)
      r.push node.getClientData()
    return r


    for node in @nodes
      r.push node.getClientData()

    return r


  getStatus : () ->
    {
      server : 'Strom'
      version : '0.0.1'
      users : @getUsersStatus()
    }


  getUsersStatus : () ->
    r = {}
    for id, user of @users
      r[id] = user.getStatus()

    return r


  turn : () =>
    @tree.clear();

    for node in @nodes
      @tree.insert(node.getX(), node.getY(), node.getWidth(), node.getHeight(), {node})

    # console.log @nodesTurn.length
    for node in @nodesTurn
      node.turn()

    # for user_id, user of @users
    #   user.turn()

    # spusteni zorbazeni FPS
    # @io.sockets.emit 'fps', @calcAverageTick()
    return false


  calcAverageTick : () ->
    diff = process.hrtime(@fpsLastTime)
    @fpsLastTime = process.hrtime()

    avgTime = do() =>
      r = 0
      for t in @fpsList
        r += t

      return r / @fpsList.length

    @fpsIndex++
    if @fpsIndex is @fps
      @fpsIndex = 0

    # 6962306 
    # delay = (diff[0] * 1e9 + diff[1])
    @fpsList[@fpsIndex] = (diff[0] + diff[1] / 1e9)

    return Math.round(60 / avgTime)

  sendTurn : () =>
    @emit 'nodes'
    @emit 'viewPort'
    # for user_id, user of @users
      # user.send 'nodes', @getNodesClientData(user.getX(), user.getY())


    return false

  run : () ->
    setInterval @turn, 1000 / @fps
    setInterval @sendTurn, 1000 / @fpsSocket
    
    @sendTurn()
    @turn()



module.exports = {Map, Server}