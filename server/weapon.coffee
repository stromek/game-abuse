require('colors')
_ = require('underscore')
Node = require('./node.coffee')


module.exports = class Weapon
  ###
    Nemuzeme pouzit @server = @player.server protoze hrac ho nemusi mit jeste nastaveny
  ###
  constructor : ( @player, @slot = -1 ) ->
    #ve milisekundach
    @callDown = 200
    @callDownTime = 0

    @acceleration = 1
    @startSpeed = 900
    @speed = 1
    @width = 5
    @height = 5
    @ammo = 0

  init : () ->
    @sendStatus()

  isReady : ( updateTime = true) ->
    time = +new Date
    if (time - @callDownTime) >= @callDown
      if updateTime is true
        # resetujeme pocitani
        @callDownTime = +new Date
      return true

    return false

  fire : ( ) ->
    if @isReady() is false
      return false

    return false

  addAmmo : ( i = 0) ->
    @ammo += i

  getNodeOptions : ( opt = {} ) ->
    opt.angle ?= @player.getAngle()

    vel = @getVelocity(opt.angle)
    opt.velX ?= vel.x
    opt.velY ?= vel.y

    pla = @getCenterPlayer()
    opt.x ?= pla.x
    opt.y ?= pla.y

    opt.width ?= @width
    opt.height ?= @height
    opt.speed ?= @speed
    opt.acceleration ?=@acceleration
    opt.jump ?= false
    opt.player = @player

    return opt

  getVelocity : ( angle = @player.getAngle() ) ->
    return {
      x : Math.cos((angle/180)*Math.PI) * (@startSpeed * @player.server.delta)
      y : Math.sin((angle/180)*Math.PI) * (@startSpeed * @player.server.delta)
    } 


  getCenterPlayer : ( ) ->
    return {
      x : (@player.getWidth() / 2) + @player.getX()
      y : (@player.getHeight() / 2) + @player.getY()
    }

  getStatus : ( ) ->
    {
      name : @constructor.name
      callDown : @callDown 
      callDownTime : @callDownTime 
      ammo : @ammo
      slot : @slot
    }

  sendStatus : ( ) ->
    @player.send 'weaponStatus', @getStatus()





class Weapon.Pistol extends Weapon
  constructor : ( ) ->
    super

    @ammo = -1
    @init()

  fire : ( ) ->
    # console.log @getNodeOptions()
    bullet = new Node.Bullet @getNodeOptions({bounce : 3, liveTime : 2000})
    @player.server.addNode bullet

    @sendStatus()




class Weapon.Shotgun extends Weapon
  constructor : ( ) ->
    super

    @width = 3
    @height = 3
    @ammo = 100
    @init()

  fire : ( ) ->
    if @isReady() is false
      return false

    if @ammo is 0
      return false
    else if @ammo > 0
      @ammo--



    angle = @player.getAngle()
    for i in [0..7]
      d = Math.round(Math.random() * 10 * i)

      tmp = do(angle) =>
        =>
          opt = @getNodeOptions {
            bounce : 1
            angle : angle + (Math.random() * 40 - 20)
            liveTime : 1000 + Math.random() * 1000
          }
          bullet = new Node.Bullet opt
          @player.server.addNode bullet

      setTimeout tmp, d

    @sendStatus()
