/*
  
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
*/

var Edge, Polygon, Projectile, Vector,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Vector = (function() {
  function Vector(x, y) {
    this.x = x;
    this.y = y;
    this.set(x, y);
  }

  Vector.prototype.set = function(x, y) {
    this.x = x != null ? x : 0.0;
    this.y = y != null ? y : 0.0;
    return this;
  };

  Vector.prototype.add = function(vector) {
    this.x += vector.x;
    this.y += vector.y;
    return this;
  };

  Vector.prototype.scale = function(scalar) {
    this.x *= scalar;
    this.y *= scalar;
    return this;
  };

  Vector.prototype.div = function(scalar) {
    this.x /= scalar;
    this.y /= scalar;
    return this;
  };

  Vector.prototype.dot = function(vector) {
    return this.x * vector.x + this.y * vector.y;
  };

  Vector.prototype.min = function(vector) {
    this.x = min(this.x, vector.x);
    return this.y = min(this.y, vector.y);
  };

  Vector.prototype.max = function(vector) {
    this.x = max(this.x, vector.x);
    return this.y = max(this.y, vector.y);
  };

  Vector.prototype.lt = function(vector) {
    return this.x < vector.x || this.y < vector.y;
  };

  Vector.prototype.gt = function(vector) {
    return this.x > vector.x || this.y > vector.y;
  };

  Vector.prototype.normalize = function() {
    var mag;
    mag = sqrt(this.x * this.x + this.y * this.y);
    if (mag !== 0) {
      this.x /= mag;
      return this.y /= mag;
    }
  };

  Vector.prototype.clone = function() {
    return new Vector(this.x, this.y);
  };

  return Vector;

})();

Edge = (function() {
  function Edge(pointA, pointB) {
    this.pointA = pointA;
    this.pointB = pointB;
  }

  Edge.prototype.intersects = function(other, ray) {
    var d, dx1, dx2, dx3, dy1, dy2, dy3, r, s;
    if (ray == null) {
      ray = false;
    }
    dy1 = this.pointB.y - this.pointA.y;
    dx1 = this.pointB.x - this.pointA.x;
    dx2 = this.pointA.x - other.pointA.x;
    dy2 = this.pointA.y - other.pointA.y;
    dx3 = other.pointB.x - other.pointA.x;
    dy3 = other.pointB.y - other.pointA.y;
    if (dy1 / dx1 !== dy3 / dx3) {
      d = dx1 * dy3 - dy1 * dx3;
      if (d !== 0) {
        r = (dy2 * dx3 - dx2 * dy3) / d;
        s = (dy2 * dx1 - dx2 * dy1) / d;
        if (r >= 0 && (ray || r <= 1)) {
          if (s >= 0 && s <= 1) {
            return new Vector(this.pointA.x + r * dx1, this.pointA.y + r * dy1);
          }
        }
      }
    }
    return false;
  };

  return Edge;

})();

Polygon = (function() {
  function Polygon(vertices, edges) {
    this.vertices = vertices != null ? vertices : [];
    this.edges = edges != null ? edges : [];
    this.colliding = false;
    this.center = new Vector;
    this.bounds = {
      min: new Vector,
      max: new Vector
    };
    this.edges = [];
    if (this.vertices.length > 0) {
      this.computeCenter();
      this.computeBounds();
      this.computeEdges();
    }
  }

  Polygon.prototype.translate = function(vector) {
    var vertex, _i, _len, _ref, _results;
    this.center.add(vector);
    this.bounds.min.add(vector);
    this.bounds.max.add(vector);
    _ref = this.vertices;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      _results.push(vertex.add(vector));
    }
    return _results;
  };

  Polygon.prototype.rotate = function(radians, pivot) {
    var c, dx, dy, s, vertex, _i, _len, _ref, _results;
    if (pivot == null) {
      pivot = this.center;
    }
    s = sin(radians);
    c = cos(radians);
    _ref = this.vertices;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      dx = vertex.x - pivot.x;
      dy = vertex.y - pivot.y;
      vertex.x = c * dx - s * dy + pivot.x;
      _results.push(vertex.y = s * dx + c * dy + pivot.y);
    }
    return _results;
  };

  Polygon.prototype.computeCenter = function() {
    var vertex, _i, _len, _ref;
    this.center.set(0, 0);
    _ref = this.vertices;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      this.center.add(vertex);
    }
    return this.center.div(this.vertices.length);
  };

  Polygon.prototype.computeBounds = function() {
    var vertex, _i, _len, _ref, _results;
    this.bounds.min.set(Number.MAX_VALUE, Number.MAX_VALUE);
    this.bounds.max.set(-Number.MAX_VALUE, -Number.MAX_VALUE);
    _ref = this.vertices;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      this.bounds.min.min(vertex);
      _results.push(this.bounds.max.max(vertex));
    }
    return _results;
  };

  Polygon.prototype.computeEdges = function() {
    var index, vertex, _i, _len, _ref, _results;
    this.edges.length = 0;
    _ref = this.vertices;
    _results = [];
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      vertex = _ref[index];
      _results.push(this.edges.push(new Edge(vertex, this.vertices[(index + 1) % this.vertices.length])));
    }
    return _results;
  };

  Polygon.prototype.contains = function(vector) {
    var edge, intersections, minX, minY, outside, ray, _i, _len, _ref,
      _this = this;
    if (vector.x > this.bounds.max.x || vector.x < this.bounds.min.x) {
      return false;
    }
    if (vector.y > this.bounds.max.y || vector.y < this.bounds.min.y) {
      return false;
    }
    minX = function(o) {
      return o.x;
    };
    minY = function(o) {
      return o.y;
    };
    outside = new Vector(Math.min.apply(Math, this.vertices.map(minX)) - 1, Math.min.apply(Math, this.vertices.map(minY)) - 1);
    ray = new Edge(vector, outside);
    intersections = 0;
    _ref = this.edges;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      edge = _ref[_i];
      if (ray.intersects(edge, true)) {
        ++intersections;
      }
    }
    return !!(intersections % 2);
  };

  Polygon.prototype.collides = function(polygon) {
    var edge, other, overlap, _i, _j, _len, _len1, _ref, _ref1;
    overlap = true;
    if (polygon.bounds.min.gt(this.bounds.max)) {
      overlap = false;
    }
    if (polygon.bounds.max.lt(this.bounds.min)) {
      overlap = false;
    }
    overlap = false;
    _ref = this.edges;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      edge = _ref[_i];
      _ref1 = polygon.edges;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        other = _ref1[_j];
        if (edge.intersects(other)) {
          return true;
        }
      }
    }
    return false;
  };

  Polygon.prototype.wrap = function(bounds) {
    var ox, oy;
    ox = (this.bounds.max.x - this.bounds.min.x) + (bounds.max.x - bounds.min.x);
    oy = (this.bounds.max.y - this.bounds.min.y) + (bounds.max.y - bounds.min.y);
    if (this.bounds.max.x < bounds.min.x) {
      this.translate(new Vector(ox, 0));
    } else if (this.bounds.min.x > bounds.max.x) {
      this.translate(new Vector(-ox, 0));
    }
    if (this.bounds.max.y < bounds.min.y) {
      return this.translate(new Vector(0, oy));
    } else if (this.bounds.min.y > bounds.max.y) {
      return this.translate(new Vector(0, -oy));
    }
  };

  Polygon.prototype.draw = function(ctx) {
    var color, vertex, _i, _len, _ref;
    color = this.colliding ? '#FF0051' : this.color;
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(this.center.x, this.center.y, 5, 0, TWO_PI);
    ctx.globalAlpha = 0.2;
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(this.bounds.min.x, this.bounds.min.y);
    ctx.lineTo(this.bounds.max.x, this.bounds.min.y);
    ctx.lineTo(this.bounds.max.x, this.bounds.max.y);
    ctx.lineTo(this.bounds.min.x, this.bounds.max.y);
    ctx.closePath();
    ctx.globalAlpha = 0.05;
    ctx.fill();
    ctx.beginPath();
    _ref = this.vertices;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      vertex = _ref[_i];
      ctx.lineTo(vertex.x, vertex.y);
    }
    ctx.closePath();
    ctx.globalAlpha = 0.8;
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.lineWidth = 2;
    return ctx.stroke();
  };

  return Polygon;

})();

Projectile = (function(_super) {
  __extends(Projectile, _super);

  function Projectile() {
    Projectile.__super__.constructor.apply(this, arguments);
    this.velocity = new Vector;
  }

  Projectile.prototype.update = function(dt) {
    return this.add(this.velocity.clone().scale(dt));
  };

  Projectile.prototype.draw = function(ctx) {
    var alpha;
    alpha = this.colliding ? 0.5 : 0.05;
    ctx.strokeStyle = '#fff';
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(this.x, this.y, 3, 0, TWO_PI);
    ctx.globalAlpha = alpha;
    ctx.lineWidth = 12;
    ctx.stroke();
    ctx.globalAlpha = 0.6;
    return ctx.fill();
  };

  Projectile.prototype.wrap = function(bounds) {
    if (this.x > bounds.max.x) {
      this.x = bounds.min.x;
    } else if (this.x < bounds.min.x) {
      this.x = bounds.max.x;
    }
    if (this.y > bounds.max.y) {
      return this.y = bounds.min.y;
    } else if (this.y < bounds.min.y) {
      return this.y = bounds.max.y;
    }
  };

  return Projectile;

})(Vector);

Sketch.create({
  COLORS: ['#0DB2AC', '#F5DD7E', '#FC8D4D', '#FC694D', '#69D2E7', '#A7DBD8', '#E0E4CC'],
  bounds: {
    min: new Vector,
    max: new Vector
  },
  makePolygon: function() {
    var mv, polygon, radius, side, sides, step, theta, vertices, _i, _ref;
    sides = random(4, 12);
    step = TWO_PI / sides;
    mv = 100;
    vertices = [];
    for (side = _i = 0, _ref = sides - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; side = 0 <= _ref ? ++_i : --_i) {
      theta = (step * side) + random(step);
      radius = random(30, 90);
      vertices.push(new Vector(radius * cos(theta), radius * sin(theta)));
    }
    polygon = new Polygon(vertices);
    polygon.translate(new Vector(random(this.width), random(this.height)));
    polygon.velocity = new Vector(random(-mv, mv), random(-mv, mv));
    polygon.color = random(this.COLORS);
    polygon.spin = random(-1, 1);
    return polygon;
  },
  makeProjectile: function() {
    var mv, projectile;
    mv = 200;
    projectile = new Projectile(random(this.width), random(this.height));
    projectile.velocity.set(random(-mv, mv), random(-mv, mv));
    return projectile;
  },
  setup: function() {
    var i;
    this.projectiles = (function() {
      var _i, _results;
      _results = [];
      for (i = _i = 0; _i <= 8; i = ++_i) {
        _results.push(this.makeProjectile());
      }
      return _results;
    }).call(this);
    return this.polygons = (function() {
      var _i, _results;
      _results = [];
      for (i = _i = 0; _i <= 12; i = ++_i) {
        _results.push(this.makePolygon());
      }
      return _results;
    }).call(this);
  },
  draw: function() {
    var dts, index, n, other, polygon, projectile, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _results;
    dts = max(0, this.dt / 1000);
    this.globalCompositeOperation = 'lighter';
    _ref = this.projectiles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      projectile = _ref[_i];
      projectile.colliding = false;
    }
    _ref1 = this.polygons;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      polygon = _ref1[_j];
      polygon.colliding = false;
    }
    _ref2 = this.polygons;
    for (index = _k = 0, _len2 = _ref2.length; _k < _len2; index = ++_k) {
      polygon = _ref2[index];
      polygon.translate(polygon.velocity.clone().scale(dts));
      polygon.rotate(polygon.spin * dts);
      polygon.computeBounds();
      polygon.wrap(this.bounds);
      _ref3 = this.projectiles;
      for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
        projectile = _ref3[_l];
        if (polygon.contains(projectile)) {
          projectile.colliding = true;
          polygon.colliding = true;
          break;
        }
      }
      if (!polygon.colliding) {
        for (n = _m = _ref4 = index + 1, _ref5 = this.polygons.length - 1; _m <= _ref5; n = _m += 1) {
          other = this.polygons[n];
          if (polygon.collides(other)) {
            polygon.colliding = true;
            other.colliding = true;
          }
        }
      }
      polygon.draw(this);
    }
    _ref6 = this.projectiles;
    _results = [];
    for (_n = 0, _len4 = _ref6.length; _n < _len4; _n++) {
      projectile = _ref6[_n];
      projectile.update(dts);
      projectile.wrap(this.bounds);
      _results.push(projectile.draw(this));
    }
    return _results;
  },
  resize: function() {
    return this.bounds.max.set(this.width, this.height);
  }
});
