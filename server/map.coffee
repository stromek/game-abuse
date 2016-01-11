
require('colors')
_ = require('underscore')

Node = require('./node.coffee')

module.exports = class Map
  constructor : () ->
    @width = 600
    @height = 400


    @width = 2500
    @height = 2500

    # Velikost cele mapy
    @width = 1200
    @height = 600

    # @width = 1800
    # @height = 750


    @data = []

  getWidth : () -> @width

  getHeight : () -> @height

  getNodes : () -> @data

  getClientData : () ->
    return {
      width : @width
      height : @height
    }

  getStartPosition : (user) ->
    id = user.getID()
    data = []
    # data.push {x : 70, y : 50}
    data.push {x : 550, y : 150}
    # data.push {x : @width - 70, y : 50}

    data.sort -> Math.random() > 0.5

    return data[0];


  load : () ->
    # // dimensions
    # @data.push({

    padding = 40

    @data.push new Node.Rectangle({
        x: 0,
        y: 0,
        width: padding,
        height: @height - padding
        solid : true
    });

    @data.push new Node.Rectangle({
        x: @width - padding,
        y: 0,
        width: padding,
        height: @height - padding
        solid : true
    });

    @data.push new Node.Rectangle({
        x: 0,
        y: @height - padding,
        width: @width,
        height: padding
        solid : true
    });

    @data.push new Node.Rectangle({
        x: padding,
        y: 0,
        width: @width - padding,
        height: padding
        solid : true
    });


    x = (posX = 0) =>
      return Math.min(padding + posX, @width - padding)
    y = (posY = 0) =>
      return Math.min(padding + posY, @height - padding)

    items = []
    items.push [x(0), y(80), 150, 50]
    items.push [x(200), y(0), 150, 100]
    items.push [x(40), y(200), 100, 25]
    items.push [x(170), y(250), 300, 25]
    items.push [x(270), y(210), 20, 40]
    items.push [x(270), y(190), 80, 20]
    items.push [x(30), y(330), 160, 25]
    items.push [x(430), y(75), 160, 25]
    items.push [x(380), y(135), 25, 25]
    items.push [x(380), y(400), 150, 25]
    items.push [x(80), y(450), 80, 25]
    items.push [x(220), y(400), 100, 25]

    cp = items
    for item in cp
      items.push [@width - item[0] - item[2], item[1], item[2], item[3]]


    for item in items
      @data.push new Node.Rectangle({
          x: item[0],
          y: item[1],
          width: item[2],
          height: item[3]
          solid : true
      });


    # t = 30
    # p = 60
    # for y in [1 .. Math.round(@height / p) - 1] by 2
    #   for x in [1 .. Math.round(@width / (p+5)) - 1] by 2

    #     @data.push new Node.Rectangle({
    #         x: _.random(x*p-t, x*p+t)
    #         y: _.random(y*p-t, y*p+t)
    #         width: _.random(p, p*5)
    #         height: _.random(20/2, p/2)
    #         solid : true
    #     });

    # for i in [0...10]
    #   @data.push new Node.Rectangle({
    #     x: _.random(0, @width)
    #     y: _.random(0, @height)
    #     width: _.random(30, 80)
    #     height: _.random(20, 50)
    #     solid : true
    #   });    
    

    
    return @