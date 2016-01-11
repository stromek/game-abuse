require('colors')
_ = require('underscore')

module.exports = class Node
  _id = 0

  constructor : ( options ) ->
    @id = _id++
    @disabled = false
    @x = options.x
    @y = options.y
    @width = options.width
    @height = options.height
    @type = @constructor.name
    @solid = options.solid ? false
    @collide = options.collide ? false
    @collideFilter = options.collideFilter ? ["*"]
    @onTurn = options.onTurn ? () -> false

    @velX = options.velX ? 0
    @velY = options.velY ? 0
    @speed = options.speed ? 0
    @acceleration = options.acceleration ? 1
    @_turn = options.turn ? false

    @allow = {
      jump : options.jump ? false
    }
    @status = { 
      jump : false
      ground : false
    }
    @action  = {
      up :  false
      down :  false
      left :  false
      right :  false
      fire : false
    }

    @gravity = options.graviy ? 0.6
    @friction = options.friction ? 0.8

    

    # console.log "new #{@constructor.name} ##{@id}".green, arguments

  destroy : ( ) =>
    @server.remNode @getID()


  collision : (dir, node) ->
    if dir is 'l' or dir is 'r'
      @velX = 0
      @status.jump = false

    else if dir is 'b'
      # @velY *= -0.2
      @velY = 
      @status.jump = false
      @status.ground = true

    else if dir is 't'
      @velY *= -0.5


  checkCollision : (shapeA, shapeB, updateShape = false) ->
    ## get the vectors to check against
    vX = (shapeA.x + (shapeA.width / 2)) - (shapeB.x + (shapeB.width / 2))
    vY = (shapeA.y + (shapeA.height / 2)) - (shapeB.y + (shapeB.height / 2))

    # add the half widths and half heights of the objects
    hWidths = (shapeA.width / 2) + (shapeB.width / 2 )

    hHeights = (shapeA.height / 2) + (shapeB.height / 2)
    colDir = null

     # if the x and y vector are less than the half width or half height, they we must be inside the object, causing a collision
    if Math.abs(vX) < hWidths and Math.abs(vY) < hHeights
      # figures out on which side we are colliding (top, bottom, left, or right)
      oX = hWidths - Math.abs(vX)
      oY = hHeights - Math.abs(vY)

      if oX >= oY
        if vY > 0
          colDir = "t"

          if updateShape is true
            shapeA.y += oY
        else 
          colDir = "b"

          if updateShape is true
            shapeA.y -= oY
      else
        if vX > 0
          colDir = "l"

          if updateShape is true
            shapeA.x += oX
        else
          colDir = "r"

          if updateShape is true
            shapeA.x -= oX

    return colDir

  setDisabled : ( @disabled ) -> @

  isDisabled : ( ) -> @disabled

  collideNode : ( node ) ->
    return false


  setServer : ( @server ) -> @

  setX : ( @x ) -> @

  setY : ( @y ) -> @
  
  setWidth : ( @width ) -> @

  setHeight : ( @height ) -> @


  getID : ( ) -> @id

  getType : ( ) -> @type

  getX : ( ) -> @x

  getY : ( ) -> @y

  getVelX : ( ) -> @velX

  getVelY : ( ) -> @velY
  
  getWidth : ( ) -> @width

  getHeight : ( ) -> @height

  isTurn : () ->
    return @_turn;

  isMoving : ( ) ->
    return @velX is 0 and @velY is 0

  isSolid : () -> @solid

  isCollide : () -> @collide

  setAction : ( @action ) -> @

  turn : ( move = @action) ->
    velX = 0
    velY = 0

    # do prava
    if @velX < @speed and move.right
      velX += @acceleration

    # do leva
    if @velX > -@speed and move.left
      velX -= @acceleration

    # skok
    if move.up and @allow.jump is true and @status.jump is false and @status.ground is true
      velY = -1200
      @status.jump = true
      @status.ground = false

    # velX *= @friction
    # velY += @gravity
    @status.ground = false

    velX *= @server.delta
    velY *= @server.delta

    @velX += velX
    @velY += velY

    @velX *= @friction
    @velY += @gravity

    @x += @velX;
    @y += @velY;

    # Kontrola na kolize
    kX = 0
    kY = 0
    kW = 0
    kH = 0

    nodes = @server.getNodes(@x - kX, @y - kY, @width + kW, @height + kH)
    for node in nodes
      if node is this
        continue

      if node.isDisabled()
        continue


      if node.collideFilter.indexOf(@constructor.name) is -1 and node.collideFilter.indexOf("*") is -1
        continue
     
      # console.log @constructor.name, node.collideFilter, node.collideFilter.indexOf(@constructor.name), node.collideFilter.indexOf("*")

      dir = @checkCollision(this, node, node.isSolid())

      if dir isnt null and node.isSolid()
        @collision(dir, node)

      if dir isnt null and node.isCollide() 
        node.collideNode(this)

    if @onTurn
      @onTurn()


  getClientData : () ->
    return {
      type : @type
      id : @id
      x : @x
      y : @y
      width : @width
      height : @height
    }





class Node.Rectangle extends Node
  constructor : () ->
    super


class Node.Player extends Node.Rectangle
  constructor : ( options) ->
    options.turn = true
    options.solid = false
    options.collide = false
    @player = options.player
    super options

    @died = false
    @diedTime = null
    # cas na respawn
    @diedCallDown = 1500
    @hp = 100

    #
    # Jaky vyrez z celkove mapy se ma pouzit pro zjisteni kolizi a zasladni uzivateli co vidi
    # width a height se scita a odecita od aktualni pozice, takze vysledky viewPort pro X: (x - viewPort.width) AŽ (x + viewPort.width)
    # cache je jen pro uzivatele abych mu poslali data drive nez je uvidi
    #
    #
    @viewPort = {
      width : 50
      height : 50
      cache : 270 + 10 # 640 x 480 (50*2 + 270 *2 = 640 + 10cache)
    }

    # natoceni zbrane
    @collide = true
    @angle = 0


  getHp : ( ) -> @hp ? 0

  getPlayer : ( ) -> @player

  demageAdd : ( dmg = 0, user = false) ->
    dmg = parseInt dmg, 10

    if @hp + dmg <= 0
      @died = true

      # je to zasah a clovk je mrvy (poprve, dalsi strela do mrtveho se nepocita)
      if @hp > 0
        @getPlayer().addDeath()
        @hp = 0
        @diedTime = (+new Date)

        if user and user.addKill
          user.addKill()

    else
      @hp = Math.max(0, @hp + dmg)
      @died = false

    @server.emit 'status'

  getClientData : () ->
    data = super
    data['angle'] = @angle
    data['hp'] = @hp
    data['viewPort'] = @getViewPort()

    return data

    return data

  getViewPort : ( cache = false) ->
    cacheSize = 0
    if cache is true
      cacheSize = @viewPort.cache + Math.abs(@velX * 10) + Math.abs(@velY * 10)

    sW = @viewPort.width + cacheSize
    sH = @viewPort.height + cacheSize

    w = @server.getMap().getWidth()
    h = @server.getMap().getHeight()

    x = Math.max(0, @getX() - sW)
    y = Math.max(0, @getY() - sH)
    width = Math.min(w, sW * 2 + @width)
    height = Math.min(h, sH * 2 + @height)

    x = Math.min(x, w - sW * 2)
    y = Math.min(y, h - sH * 2)    

    return {x, y, width, height}

  respawn : () ->
    @hp = 100
    @died = false

    startPosition = @server.map.getStartPosition(@player)
    @setX startPosition.x
    @setY startPosition.y

    @server.emit 'status'

  turn : () =>
    # cas na respawn
    if @died is true and @diedTime < ((+new Date) - @diedCallDown)

      @respawn()
    # jen mrtvej
    else if @died is true
      super {}

    else if @died is false
      super

    # nevim k cemu to je
    # @angle++
    # @angle = @angle % 360


class Node.Bullet extends Node.Rectangle
  constructor : ( options ) ->
    @demage = options.demage ? 10
    @startDate = (+new Date)
    @liveTime = options.liveTime ? 0
    @player = options.player
    @bounce = options.bounce ? 0

    options.turn = true
    options.solid = false
    options.collide = true
    options.graviy = 0
    options.friction = 1
    options.collideFilter = ['Player']
    super options

  getPlayer : ( ) -> @player

  collision : (dir, node) ->
    if @bounce is 0
      @destroy()
      return false

    if @bounce > 0
      @bounce--

    # return false

    if dir is 'l' or dir is 'r'
      @velX *= -1

    if dir is 'b' or dir is 't'
      @velY *= -1

    return true


  collideNode : ( node ) =>
    # console.log Date(), this.type, node.getType()
    if node.getID() is @player.getNodeID()
      return false

    @destroy()
    node.demageAdd -@demage, @player

    # @player.addKill()
    # node.getPlayer().addDeath()
    
    # console.log Date() + "Colide: #{@getType()} ##{@id} (from: #{@player.getID()}) -> #{node.getType()} #{node.getID()}"


  getClientData : () ->
    data = super
    data['demage'] = @angle

    return data

  turn : () ->
    if @liveTime isnt 0 and ((+new Date) - @startDate) > @liveTime
      @destroy()
      # console.log new Date() + " destroy bullet "
    super

class 