require('colors')
_ = require('underscore')

Node = require('./node.coffee')
Weapon = require('./weapon.coffee')

module.exports = class User
  constructor : () ->
    @id = null
    # Reference na obejtk na mape Node.Player
    @node = null
    @socket = null
    @name = "Player"
    @score = {
      kill : 0
      death : 0
    }
    @weapon = 1
    @weaponCalldown = 0
    @keys = {
      up : false
      down : false
      left : false
      right : false
      fire : false
      fire2 : false
    }
    @weapons = {
      0 : new Weapon.Pistol(@, 0)
      1 : new Weapon.Shotgun(@, 1)
    }

  send : ( name, value ) ->
    if @socket and @socket.emit
      @socket.emit name, value

  destroy : ( ) ->
    if @node
      @server.remNode(@node.getID())


  init : (data) ->
    @socket.emit 'user_id', @id

    @node = new Node.Player({
      x: data.x,
      y: data.y,
      width: 16,
      height: 16
      speed : 2
      acceleration : 300
      jump : true
      onTurn : @turn
      player : @
    });
    @server.addNode @node

    # Zbrane
    for slot, weapon of @weapons
      weapon.sendStatus()

  getViewPort : (cache = false) ->
    if @node
      return @node.getViewPort(cache)

    return {x : 0, y : 0, width : 0, height : 0}
    
  getAngle : () ->
    return @keys.args.angle ? 0

  getX : () -> @node and @node.getX()

  getY : () -> @node and @node.getY()

  getWidth : () -> @node and @node.getWidth()

  getHeight : () -> @node and @node.getHeight()

  setSocket : ( @socket ) -> @

  setServer : ( @server ) -> @

  setName : ( @name ) -> @

  setID : ( @id ) ->
    @setName "Player ##{@id}"

  getStatus : ( ) ->
    {@name, @score, @weapon, hp : @node.getHp(), @id, viewPort : @getViewPort()}

  addKill : ( i = 1) ->
    @score.kill += i
    @server.emit 'status'

  addDeath : ( i = 1) ->
    @score.death += i
    @server.emit 'status'

  getID : ( ) -> @id

  getVelX : ( ) -> @node.getVelX()

  getVelY : ( ) -> @node.getVelY()

  getNodeID : ( ) ->
    if @node
      return @node.getID()

    return -1

  setKeys : ( keys ) ->
    @keys = {
      up :  keys.up is true
      down :  keys.down is true
      left :  keys.left is true
      right :  keys.right is true
      fire : keys.fire is true
      fire2 : keys.fire2 is true
      args : keys.args
    }

    if @node
      @node.setAction @keys


  turn : ( ) =>
    @weaponCalldown = Math.max(0, --@weaponCalldown)

    # pokud strilim a pokud jeste hrac nema vytvoreny vlastni nod
    if @keys.fire and @node
      @keys.fire = false
      @weapons['0'].fire()

    if @keys.fire2 and @node
      @keys.fire2 = false
      @weapons['1'].fire()

    # if @weaponCalldown is 0 and @keys.fire
    #   @keys.fire = false
    #   @weaponCalldown = 50 * @server.delta
    #   angle = @keys.args.angle ? 0
    #   # distance = @keys.args.distance ? 10
    #   distance = 950

    #   # this.left += Math.cos((angle/180)*Math.PI)*5;
    #   # this.top += Math.sin((angle/180)*Math.PI)*5;


    #   dX = (@getWidth() / 2)
    #   dY = (@getHeight() / 2)



    #   bullet = new Node.Bullet({
    #     x: @getX() + dX,
    #     y: @getY() + dY,
    #     velX : Math.cos((angle/180)*Math.PI) * (distance * @server.delta)
    #     velY : Math.sin((angle/180)*Math.PI) * (distance * @server.delta)
    #     width: 5,
    #     height: 5
    #     speed : 1
    #     acceleration : 1
    #     jump : false
    #     player : @
    #   })

    #   @server.addNode bullet


    # @node.doMove(@keys)