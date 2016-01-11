`(function() {
    var lastTime = 0;
    var vendors = ['webkit', 'moz'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame =
          window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
              timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };

    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());`

# window.console.log_ = window.console.log
window.console.error_ = window.console.error

window.console.error = () ->
  window.console.write 'error', arguments

# window.console.log = () ->
#   window.console.write 'log', arguments

window.console.write = (type = 'log', data) ->
  area = document.getElementById('debugArea')

  str = []
  for item in data

    switch typeof(item)
      when 'object'
        name = item.constructor.name
        if name is 'Object'
          str.push "<span>"+JSON.stringify(item).substr(0, 200)+"</span>"
        else
          str.push item.constructor.name

      else
        str.push JSON.stringify(item)


  if not area._i
    area._i = 1

  area.innerHTML = "<div class='item #{type}'>##{area._i}: " + str.join(', ') + "</div>" + area.innerHTML
  area._i++

  if type is 'log'
    window.console.log.apply(window.console, data)
  if type is 'error'
    window.console.error_.apply(window.console, data)

window.onerror = () ->
  window.console.write 'error', arguments




class Abuse
  constructor : (@scope) ->
    @fps = 120
    @fpsStatic = 5
    @fpsKey = 120
    @keys = {}


    @socket = io.connect('http://192.168.135.50');

    @nodes = {}
    # Nody ktere musiem po preklresnei odsatrnit z @nodes
    @deleteNodeList = []
    @status = {}
    @userStatus = {}
    @map = {
      width : 0
      height : 0
      stage : null
      layers : {
        player : null
        node : null
      }
      deleteDraw : 150,
      draw : {
        player : 1
        node : 1
      }
      drawNow : {
        player : false
        node : false
      }
    }
    @viewPort = {
      x : 0
      y : 0
      width : 0
      height : 0
    }
    @desktop = {
      width : 640
      height : 480
    }
    # Zda bezi prekreslovani v metode @drawStart
    @isRunning = false

    # nastaveni scope
    @scope.weapons = {}
    @scope.status = {}

    window['APP'] = {abuse : @, @map, @nodes, @socket, @status, @userStatus}
    window['MAP'] = @map

    @socket.on 'status', @setStatus
    @socket.on 'userstatus', @setUserStatus
    @socket.on 'nodes', @setNodes
    @socket.on 'map', @setMap
    @socket.on 'remNode', @remNode
    @socket.on 'user_id', @setUser_id
    @socket.on 'viewPort', @setViewPort
    @socket.on 'fps', @setServerFPS
    @socket.on 'weaponStatus', @setWeaponStatus


    $(document).on 'keydown', @keyDown
    $(document).on 'keyup', @keyUp


  keyDown : ( e ) =>
    @keys[e.keyCode] = true

    @sendKeys()

    if e.keyCode in [32,37,38,39,40,83,87]
      e.stopPropagation()
      return false

    return true

  keyUp : ( e ) =>
    @keys[e.keyCode] = false
    @sendKeys()

    return true

  setUser_id : ( @user_id ) => @

  setServerFPS  : ( fps ) =>
    document.getElementById('serverFps').innerHTML = fps


  setViewPort : ( @viewPort ) =>
    # y = -(@map.stage.getY() + @viewPort.y - (@viewPort.height / 2))

    x = -(@viewPort.x - @desktop.width / 2)
    y = -(@viewPort.y - @desktop.height / 2)

    x = Math.min(x, 0)
    x = Math.max(x, @desktop.width - @map.width)

    y = Math.min(y, 0)
    y = Math.max(y, @desktop.height - @map.height)

    
    x = x - @map.stage.getX()
    y = y - @map.stage.getY()

    @map.stage.move(x, y)


    return false

  sendKeys : ( opt = {}, args = {} ) ->
    data = {
      up    : (@keys[38] or @keys[87] or opt.up)
      down  : (@keys[40] or @keys[83] or opt.down)
      left  : (@keys[37] or @keys[65] or opt.left)
      right : (@keys[39] or @keys[68] or opt.right)
      fire  : (@keys[32] or opt.fire)
      fire2  : (opt.fire2 ? false)
      args : args ? {}
    }

    @send 'keys', data


  send : ( name, data) ->
    @socket.emit name, data


  setMap : ( data ) =>
    @map.width = data.width
    @map.height = data.height


    if @map.stage
      @nodes = {}
      @map.stage.destroyChildren()
      @map.stage.destroy()
      @map.stage = null


    @map.stage = new Kinetic.Stage {
      width  : @desktop.width
      height : @desktop.height
      container : 'container'
    }

    # @map.stage.on 'mousemove', ( e ) =>
    #   @map.stage.

    @map.stage.on 'mousedown', ( e ) =>
      # @map.stage.on 'mouseup'
      button = e.button ? 0

      # e.cancelBubble = true

      # offset na canvas + offset na mapu
      offset = $(@map.stage.content).offset()
      x = (e.clientX - offset.left) - @map.stage.getX()
      y = (e.clientY - offset.top) - @map.stage.getY()

      node = @nodes[@userStatus.nodes.player]
      # console.log node.width / 2, node.height / 2


      deltaX = x - (node.x + (node.width / 2))
      deltaY = y - (node.y + (node.height / 2))

      angle = Math.atan2(deltaY, deltaX) * 180 / Math.PI
      distance = Math.sqrt(Math.pow(deltaX, 2) + Math.pow(deltaY, 2))
      # console.log "ANGLE : ", angle, "distance:", distance

      if button is 0
        @sendKeys { fire : true}, {angle, distance}
      else if button is 2
        @sendKeys { fire2 : true}, {angle, distance}
        return false

      return true


    # Vytvorime vrsty. Name se musi shodovat s klicem
    @map.layers.node = new Kinetic.Layer {name : 'node'}
    @map.layers.player = new Kinetic.Layer {name : 'player'}

    for name, layer of @map.layers when layer
      @map.stage.add layer

    @drawStart()

    return true


  ### 
    Spusteni prekreslovani canvasu, metoda se spusti po nastaveni mapy @setMap
    Pokud bezi je @isRunning true
  ###
  drawStart : () ->
    if @isRunning
      return false

    @isRunning = true

    # vykreslime objekty
    # @draw()
    # @drawStatic()
    index = 0
    # maxFrame = _.max(@map.draw)

    tmp = () =>
      # Pokud jsem na maximalnim framu muzu vynulovat (nepouziva se, musel by to byt nasobek vsech - nejvyssi spolecni delitel)
      # if index is maxFrame
      #   index = 0

      for layerName, frame of @map.draw
        # pokud existuej vrstva
        if @map.layers[layerName]

          # a mame ji prekleslit
          if index % frame is 0
            @drawLayer(layerName)

          # nebo ji mame vykreslit hned
          else if @map.drawNow[layerName] is true
            @map.drawNow[layerName] = false
            @drawLayer(layerName)


      if index % @map.deleteDraw is 0
        @collectDeleteNode()
      
      index++
      window.requestAnimationFrame tmp
      true

    window.requestAnimationFrame tmp


  ###
    Prekresleni vrstvy v nasledujicim framu
  ###
  drawNow : ( layerName ) ->
    if @map.layers[layerName]
      @map.drawNow[layerName] = true


  remNode : ( id ) =>
    if @nodes[id]
      layerName = @nodes[id].getLayer().getName()
      @nodes[id].destroy()
      @drawNow layerName
      @deleteNodeList.push id
      console.log "MAZU ID: ##{id}"


  drawLayer : ( layerName) ->
    # if layerName is 'node'
    #   return false

    # console.log "Drow: #{layerName}"
    @map.layers[layerName].batchDraw()

    return true

  collectDeleteNode : () ->
    if @deleteNodeList.length is 0
      return false

    for node_id in @deleteNodeList
      delete @nodes[node_id]

    @deleteNodeList.length = 0
    return true


  ###
    Pridani noveho objektu do platna
  ###
  setNodes : ( nodes ) =>
    for data in nodes
      if not @nodes[data.id]
        # Do ktere vrstvy budeme zapisovat
        layer = @getLayerByType(data.type)
        # vytvorime nod
        @nodes[data.id] = @createNode(data.type, data.id, layer)

        # Nastavime ze se dana vrstva ma hned v dalsim kroku prekreslit
        @drawNow layer.getName()

      @nodes[data.id].setData(data)

    return @

  setUserStatus : ( @userStatus ) =>
    console.log "client.setUserStatus()", @userStatus
    @

  setWeaponStatus : (weapon) =>
    @scope.$apply () =>
      @scope.weapons[weapon.slot] = weapon

      # if weapon.callDownTime > 0
      #   console.log ("")


    console.log "client.setWeaponStatus(): ", weapon

  # Status serveru
  setStatus : ( @status ) =>
    @scope.$apply () =>
      @scope.status = @status

    console.log "client.setStatus(): ", @status
    return @

      # socket.emit('my other event', { my: 'data' });

    return true

  getLayerByType : (type) ->
    switch type.toLowerCase()
      when "player", "bullet", "debug"
        return @map.layers.player

      else  
        return @map.layers.node

  hightlightNode : (node) =>
    return false
    tmp = () =>
      clone = node.getObj().clone()
      clone.remove()

      # clone.setFill('gold')
      @getLayerByType('debug').add clone
      clone.moveUp()

      period = 200
      blur = 30
      lastBlur = blur
      clone.setShadowBlur(blur)

      tmp2 = () ->
        clone.setShadowBlur(0)
        clone.destroy()
      window.setTimeout tmp2, 100
      return true

      animationStep = (frame) ->
        o = Math.floor(Math.min(frame.time, period) / period * 100)
        if o isnt lastBlur
          lastBlur = o
          clone.setShadowBlur(blur - (blur / 100 * o))

        if frame.time > period
          clone.destroy()
          @stop()
          delete anim
    
      # anim = new Kinetic.Animation animationStep, @getLayerByType('debug')
      # anim.start()

    window.setTimeout tmp, 20


  createNode : (type, id, layer) ->
    node = false

    switch type.toLowerCase()
      when "rectangle"
        node = new Node.Rectangle(id, layer, @scope)

      when "player"
        node = new Node.Player(id, layer, @scope)
        # console.log window['x'] = node

      when "bullet"
        node = new Node.Bullet(id, layer, @scope)

      else
        console.log "Chyba ! Neznam typ: #{type}"
        node = new Node(id, layer, @scope)


    #DEBUG
    # if node and node.getObj() and type.toLowerCase() in ['rectangle']
    #   @hightlightNode node
      

    return node




class Node
  constructor : ( @id, @layer, @scope ) ->
    # @obj = null
    @active = false

    @x = 0
    @y = 0
    @width = 0
    @height = 0

    # Pokud je true, editujeme v editoru objekt a tedy nesmime ho menit pokud prijde zmena ze serveru
    @editMode = false

    return true


  setData : (data) ->
    @x = data.x
    @y = data.y
    @width = data.width
    @height = data.height

    return true

  debugNode : ( obj ) ->
    obj.on 'mouseenter', () ->
      obj.setOpacity(0.7)
    obj.on 'mouseleave', () ->
      obj.setOpacity(1)

    obj.on 'dragend', () =>
      console.log(obj.getX(), obj.getY())
      console.log('dragend');

    obj.on 'dragstart', () =>
      @setEditMode (true)
      console.log('START !');

    # obj.draggable(true);
    obj.setDraggable(true)

  destroy : ( ) ->
    true

  setEditMode : ( @editMode) ->

  getObj : ( ) ->
    @obj ? false

  getLayer : ( ) ->
    @layer

  getLayerName : ( ) ->
    @layer.getName()


class Node.Rectangle extends Node
  constructor : () ->
    super

    @obj = new Kinetic.Rect {
      x: @x
      y: @y
      width: @width
      height: @height
      fill: '#aaa'
    }

    @layer.add(@obj)

    # DEBUGOVANI !
    # @debugNode @obj

  setData : (data) ->
    super
    
    if @editMode is false
      @obj.move(data.x - @obj.getX(), data.y - @obj.getY())
      @obj.setHeight(data.height)
      @obj.setWidth(data.width)

    return true

  destroy : ( ) ->
    super
    @obj.destroy()




class Node.Player extends Node
  constructor : () ->
    super

    @hp = -1
    @viewPort = {x : 0, y : 0, width : 100, height : 100}


    img = new Image()
    img.onerror = () ->
      console.error "Chyba nacitani obrazku #{@src}"
    img.onload = () =>
      # @obj = new Kinetic.Sprite {
      #   x: @x
      #   y: @y 
      #   image : img
      #   width: @width
      #   height: @height
      #   animation : 'idle'
      #   animations : {
      #     idle : makeAnimation(66, 84, 11, 13, {first : 116, cnt : 3})
      #   }
      #   index : 0
      #   frameRate : 3
      # }

      @obj = new Kinetic.Rect {
        x: @x
        y: @y 
        width: @width
        height: @height
        fill : 'magenta'
      }

      # @objViewPort = new Kinetic.Rect({
      #   x: 0,
      #   y: 0,
      #   width: 10,
      #   height: 10,
      #   fill: '#fca',
      #   opacity : 0.3
      # });

      # @layer.add(@objViewPort);
      @layer.add(@obj)

      # pokud je to sprite
      if @obj.start
        @obj.start()
      
    img.src = '/img/2_cop.png'
    # smw_mario_sheet.png

  # Prichozi data ze serveru (pozice, hp, pohled apod.)
  setData : (data) ->
    super
    @hp = data.hp
    @viewPort = data.viewPort

    # if @objViewPort
    #   @objViewPort.move(@viewPort.x - @objViewPort.getX(), @viewPort.y - @objViewPort.getY())
    #   @objViewPort.setHeight(@viewPort.height)
    #   @objViewPort.setWidth(@viewPort.width)

    if @obj and @editMode is false
      @obj.move(data.x - @obj.getX(), data.y - @obj.getY())
      @obj.setHeight(data.height)
      @obj.setWidth(data.width)

      # console.log @id
      # move(-100, 0)move(-100, 0)

      color = [Number(Math.round(255 / 100 * ( 100 - @hp ))).toString(16), '00', '00']
      if color[0].length is 0
        color[0] = "0#{color[0]}"

      @obj.setFill(color.join(''))

    return true
    
    # console.log "AA!", @viewP/ort

  destroy : ( ) ->
    super
    @obj.destroy()
    # @objViewPort.destroy()


class Node.Bullet extends Node
  constructor : () ->
    super

    @obj = new Kinetic.Rect {
      x: @x
      y: @y 
      width: @width
      height: @height
      fill : 'red'
    }

    window['OBJ'] = @obj

    @layer.add(@obj)

  setData : (data) ->
    super
    
    if @editMode is false
      @obj.move(data.x - @obj.getX(), data.y - @obj.getY())
      @obj.setHeight(data.height)
      @obj.setWidth(data.width)

    return true

  destroy : ( ) ->
    super
    @obj.destroy()




Abuse.$inject = ['$scope']

app = angular.module('Abuse', [])
app.controller('Abuse', Abuse)




makeAnimation = (w, h, rows = 1, cols = 1, opt = {}) ->
  opt.last ?= 0
  opt.first ?= 0
  opt.x ?= 0
  opt.y ?= 0
  opt.xs ?= 0
  opt.ys ?= 0
  opt.cnt ?= 0

  r = []
  for y in [0...cols]
    for x in [0...rows]
      r.push {
        width : w
        height : h
        x : w * (x + opt.xs)
        y : h * (y + opt.ys)
      }

  if opt.first
    r = r.slice(opt.first)

  if opt.last
    r = r.slice(0, -opt.last)

  if opt.cnt
    r = r.slice(0, opt.cnt)

  # console.log r

  return r  














