###
  
  Demonstrates collision detection between convex and non-convex polygons
  and how to detect whether a point vector is contained within a polygon

  Possible techniques:

    x Bounding box or radii
      Inacurate for complex polygons

    x SAT (Separating Axis Theorem)
      Only handles convex polygons, so non-convex polygons must be subdivided

    x Collision canvas. Draw polygon A then polygon B using `source-in`
      Slow since it uses getImageData and pixels must be scanned. Algorithm
      can be improved by drawing to a smaller canvas but downsampling effects
      accuracy and using canvas transformations (scale) throws false positives

    - Bounding box + line segment intersection
      Test bounding box overlap (fast) then proceed to per edge intersection
      detection if necessary. Exit after first intersection is found since
      we're not simulating collision responce. This technique fails to detect
      nested polygons, but since we're testing moving polygons it's ok(ish)
  
###

class Vector
  
  constructor: ( @x, @y ) -> @set x, y
    
  set: ( @x = 0.0, @y = 0.0 ) -> @
    
  add: ( vector ) ->
    
    @x += vector.x
    @y += vector.y 
    @
      
  scale: ( scalar ) ->
    
    @x *= scalar
    @y *= scalar
    @

  div: ( scalar ) ->

    @x /= scalar
    @y /= scalar
    @
      
  dot: ( vector ) ->
    
    @x * vector.x + @y * vector.y

  min: ( vector ) ->

    @x = min @x, vector.x
    @y = min @y, vector.y

  max: ( vector ) ->

    @x = max @x, vector.x
    @y = max @y, vector.y

  lt: ( vector ) ->

    @x < vector.x or @y < vector.y

  gt: ( vector ) ->

    @x > vector.x or @y > vector.y
    
  normalize: ->
    
    mag = sqrt @x*@x + @y*@y
      
    if mag isnt 0
      @x /= mag
      @y /= mag
        
  clone: ->
          
    new Vector @x, @y

class Edge

  constructor: ( @pointA, @pointB ) ->

  intersects: ( other, ray = no ) ->

    dy1 = @pointB.y - @pointA.y
    dx1 = @pointB.x - @pointA.x
    dx2 = @pointA.x - other.pointA.x
    dy2 = @pointA.y - other.pointA.y
    dx3 = other.pointB.x - other.pointA.x
    dy3 = other.pointB.y - other.pointA.y

    if dy1 / dx1 isnt dy3 / dx3
    
      d = dx1 * dy3 - dy1 * dx3

      if d isnt 0
      
        r = (dy2 * dx3 - dx2 * dy3) / d
        s = (dy2 * dx1 - dx2 * dy1) / d

        if r >= 0 and ( ray or r <= 1 )

          if s >= 0 and s <= 1
          
            return new Vector @pointA.x + r * dx1, @pointA.y + r * dy1

    no

    
class Polygon
  
  constructor: ( @vertices = [], @edges = [] ) ->
    
    @colliding = no
    @center = new Vector
    @bounds = min: new Vector, max: new Vector
    @edges = []

    if @vertices.length > 0
      
      @computeCenter()
      @computeBounds()
      @computeEdges()
    
  translate: ( vector ) ->
    
    @center.add vector
    @bounds.min.add vector
    @bounds.max.add vector
    vertex.add vector for vertex in @vertices

  rotate: ( radians, pivot = @center ) ->

    s = sin radians
    c = cos radians

    for vertex in @vertices

      dx = vertex.x - pivot.x
      dy = vertex.y - pivot.y

      vertex.x = c * dx - s * dy + pivot.x
      vertex.y = s * dx + c * dy + pivot.y

  computeCenter: ->

    @center.set 0, 0
    @center.add vertex for vertex in @vertices
    @center.div @vertices.length

  computeBounds: ->

    @bounds.min.set Number.MAX_VALUE, Number.MAX_VALUE
    @bounds.max.set -Number.MAX_VALUE, -Number.MAX_VALUE

    for vertex in @vertices
      @bounds.min.min vertex
      @bounds.max.max vertex
      
  computeEdges: ->

    @edges.length = 0

    for vertex, index in @vertices
      @edges.push new Edge vertex, @vertices[ (index + 1) % @vertices.length ]
    
  contains: ( vector ) ->
        
    return no if vector.x > this.bounds.max.x or vector.x < this.bounds.min.x
    return no if vector.y > this.bounds.max.y or vector.y < this.bounds.min.y

    minX = (o) => o.x
    minY = (o) => o.y

    outside = new Vector(
      Math.min.apply( Math, this.vertices.map( minX ) ) - 1,
      Math.min.apply( Math, this.vertices.map( minY ) ) - 1)

    ray = new Edge vector, outside
    intersections = 0

    ( ++intersections if ray.intersects edge, yes ) for edge in @edges

    !!( intersections % 2 )

  collides: ( polygon ) ->

    overlap = yes

    # First perform a simple boundary check
    overlap = no if polygon.bounds.min.gt @bounds.max
    overlap = no if polygon.bounds.max.lt @bounds.min
    
    # Perform per edge intersection tests if bounds overlap
    overlap = no

    for edge in @edges

      for other in polygon.edges

        return yes if edge.intersects other

    no

  wrap: ( bounds ) ->
         
    ox = (@bounds.max.x - @bounds.min.x) + (bounds.max.x - bounds.min.x)
    oy = (@bounds.max.y - @bounds.min.y) + (bounds.max.y - bounds.min.y)

    if @bounds.max.x < bounds.min.x then @translate new Vector ox, 0
    else if @bounds.min.x > bounds.max.x then @translate new Vector -ox, 0

    if @bounds.max.y < bounds.min.y then @translate new Vector 0, oy
    else if @bounds.min.y > bounds.max.y then @translate new Vector 0, -oy
    
  draw: ( ctx ) ->

    color = if @colliding then '#FF0051' else @color

    ctx.strokeStyle = color
    ctx.fillStyle = color

    # center
    ctx.beginPath()
    ctx.arc @center.x, @center.y, 5, 0, TWO_PI
    ctx.globalAlpha = 0.2
    ctx.stroke()

    # bounds
    ctx.beginPath()
    ctx.moveTo @bounds.min.x, @bounds.min.y
    ctx.lineTo @bounds.max.x, @bounds.min.y
    ctx.lineTo @bounds.max.x, @bounds.max.y
    ctx.lineTo @bounds.min.x, @bounds.max.y
    ctx.closePath()
    ctx.globalAlpha = 0.05
    ctx.fill()
    
    # polygon
    ctx.beginPath()
    ctx.lineTo vertex.x, vertex.y for vertex in @vertices
    ctx.closePath()

    ctx.globalAlpha = 0.8
    ctx.fill()
                  
    ctx.globalAlpha = 1
    ctx.lineWidth = 2
    ctx.stroke()


class Projectile extends Vector

  constructor: ->

    super

    @velocity = new Vector

  update: ( dt ) ->

    @add @velocity.clone().scale dt

  draw: ( ctx ) ->
    
    alpha = if @colliding then 0.5 else 0.05
      
    ctx.strokeStyle = '#fff'
    ctx.fillStyle = '#fff'

    ctx.beginPath()
    ctx.arc @x, @y, 3, 0, TWO_PI
      
    ctx.globalAlpha = alpha
    ctx.lineWidth = 12
    ctx.stroke()
      
    ctx.globalAlpha = 0.6
    ctx.fill()

  wrap: ( bounds ) ->

    if @x > bounds.max.x then @x = bounds.min.x
    else if @x < bounds.min.x then @x = bounds.max.x

    if @y > bounds.max.y then @y = bounds.min.y
    else if @y < bounds.min.y then @y = bounds.max.y

# Example

Sketch.create

  COLORS: [ '#0DB2AC', '#F5DD7E', '#FC8D4D', '#FC694D', '#69D2E7', '#A7DBD8', '#E0E4CC' ]
     
  bounds:
    min: new Vector
    max: new Vector
      
  makePolygon: ->

    sides = random 4, 12
    step = TWO_PI / sides
    mv = 100

    vertices = []
                 
    for side in [0..sides-1]
                 
      theta = (step * side) + random step
      radius = random 30, 90

      vertices.push new Vector (radius * cos theta), (radius * sin theta)
        
    polygon = new Polygon vertices
    polygon.translate new Vector (random @width), (random @height)
    polygon.velocity = new Vector (random -mv, mv), (random -mv, mv)
    polygon.color = random @COLORS
    polygon.spin = random -1, 1
      
    polygon

  makeProjectile: ->

    mv = 200

    projectile = new Projectile (random @width), (random @height)
    projectile.velocity.set (random -mv, mv), (random -mv, mv)
    projectile
    
  setup: ->
        
    @projectiles = ( do @makeProjectile for i in [0..8] )
    @polygons = ( do @makePolygon for i in [0..12] )

  draw: ->
    
    dts = max 0, this.dt / 1000
    
    @globalCompositeOperation = 'lighter'

    projectile.colliding = no for projectile in @projectiles
    polygon.colliding = no for polygon in @polygons

    for polygon, index in @polygons

      polygon.translate polygon.velocity.clone().scale dts
      polygon.rotate polygon.spin * dts
      polygon.computeBounds()
      polygon.wrap @bounds

      # test collisions

      for projectile in @projectiles

        if polygon.contains projectile

          projectile.colliding = yes
          polygon.colliding = yes

          break

      if not polygon.colliding

        for n in [index+1..@polygons.length-1] by 1

          other = @polygons[ n ]
          
          if polygon.collides other

            polygon.colliding = yes
            other.colliding = yes
          
      polygon.draw @
          
    for projectile in @projectiles

      projectile.update dts
      projectile.wrap @bounds
      projectile.draw @

  resize: ->

    @bounds.max.set @width, @height
        