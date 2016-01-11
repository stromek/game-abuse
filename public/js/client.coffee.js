(function() {
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
}());;
var Abuse, Node, app, makeAnimation,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

window.console.error_ = window.console.error;

window.console.error = function() {
  return window.console.write('error', arguments);
};

window.console.write = function(type, data) {
  var area, item, name, str, _i, _len;
  if (type == null) {
    type = 'log';
  }
  area = document.getElementById('debugArea');
  str = [];
  for (_i = 0, _len = data.length; _i < _len; _i++) {
    item = data[_i];
    switch (typeof item) {
      case 'object':
        name = item.constructor.name;
        if (name === 'Object') {
          str.push("<span>" + JSON.stringify(item).substr(0, 200) + "</span>");
        } else {
          str.push(item.constructor.name);
        }
        break;
      default:
        str.push(JSON.stringify(item));
    }
  }
  if (!area._i) {
    area._i = 1;
  }
  area.innerHTML = ("<div class='item " + type + "'>#" + area._i + ": ") + str.join(', ') + "</div>" + area.innerHTML;
  area._i++;
  if (type === 'log') {
    window.console.log.apply(window.console, data);
  }
  if (type === 'error') {
    return window.console.error_.apply(window.console, data);
  }
};

window.onerror = function() {
  return window.console.write('error', arguments);
};

Abuse = (function() {
  function Abuse(scope) {
    this.scope = scope;
    this.hightlightNode = __bind(this.hightlightNode, this);
    this.setStatus = __bind(this.setStatus, this);
    this.setWeaponStatus = __bind(this.setWeaponStatus, this);
    this.setUserStatus = __bind(this.setUserStatus, this);
    this.setNodes = __bind(this.setNodes, this);
    this.remNode = __bind(this.remNode, this);
    this.setMap = __bind(this.setMap, this);
    this.setViewPort = __bind(this.setViewPort, this);
    this.setServerFPS = __bind(this.setServerFPS, this);
    this.setUser_id = __bind(this.setUser_id, this);
    this.keyUp = __bind(this.keyUp, this);
    this.keyDown = __bind(this.keyDown, this);
    this.fps = 120;
    this.fpsStatic = 5;
    this.fpsKey = 120;
    this.keys = {};
    this.socket = io.connect('http://192.168.135.50');
    this.nodes = {};
    this.deleteNodeList = [];
    this.status = {};
    this.userStatus = {};
    this.map = {
      width: 0,
      height: 0,
      stage: null,
      layers: {
        player: null,
        node: null
      },
      deleteDraw: 150,
      draw: {
        player: 1,
        node: 1
      },
      drawNow: {
        player: false,
        node: false
      }
    };
    this.viewPort = {
      x: 0,
      y: 0,
      width: 0,
      height: 0
    };
    this.desktop = {
      width: 640,
      height: 480
    };
    this.isRunning = false;
    this.scope.weapons = {};
    this.scope.status = {};
    window['APP'] = {
      abuse: this,
      map: this.map,
      nodes: this.nodes,
      socket: this.socket,
      status: this.status,
      userStatus: this.userStatus
    };
    window['MAP'] = this.map;
    this.socket.on('status', this.setStatus);
    this.socket.on('userstatus', this.setUserStatus);
    this.socket.on('nodes', this.setNodes);
    this.socket.on('map', this.setMap);
    this.socket.on('remNode', this.remNode);
    this.socket.on('user_id', this.setUser_id);
    this.socket.on('viewPort', this.setViewPort);
    this.socket.on('fps', this.setServerFPS);
    this.socket.on('weaponStatus', this.setWeaponStatus);
    $(document).on('keydown', this.keyDown);
    $(document).on('keyup', this.keyUp);
  }

  Abuse.prototype.keyDown = function(e) {
    var _ref;
    this.keys[e.keyCode] = true;
    this.sendKeys();
    if ((_ref = e.keyCode) === 32 || _ref === 37 || _ref === 38 || _ref === 39 || _ref === 40 || _ref === 83 || _ref === 87) {
      e.stopPropagation();
      return false;
    }
    return true;
  };

  Abuse.prototype.keyUp = function(e) {
    this.keys[e.keyCode] = false;
    this.sendKeys();
    return true;
  };

  Abuse.prototype.setUser_id = function(user_id) {
    this.user_id = user_id;
    return this;
  };

  Abuse.prototype.setServerFPS = function(fps) {
    return document.getElementById('serverFps').innerHTML = fps;
  };

  Abuse.prototype.setViewPort = function(viewPort) {
    var x, y;
    this.viewPort = viewPort;
    x = -(this.viewPort.x - this.desktop.width / 2);
    y = -(this.viewPort.y - this.desktop.height / 2);
    x = Math.min(x, 0);
    x = Math.max(x, this.desktop.width - this.map.width);
    y = Math.min(y, 0);
    y = Math.max(y, this.desktop.height - this.map.height);
    x = x - this.map.stage.getX();
    y = y - this.map.stage.getY();
    this.map.stage.move(x, y);
    return false;
  };

  Abuse.prototype.sendKeys = function(opt, args) {
    var data, _ref;
    if (opt == null) {
      opt = {};
    }
    if (args == null) {
      args = {};
    }
    data = {
      up: this.keys[38] || this.keys[87] || opt.up,
      down: this.keys[40] || this.keys[83] || opt.down,
      left: this.keys[37] || this.keys[65] || opt.left,
      right: this.keys[39] || this.keys[68] || opt.right,
      fire: this.keys[32] || opt.fire,
      fire2: (_ref = opt.fire2) != null ? _ref : false,
      args: args != null ? args : {}
    };
    return this.send('keys', data);
  };

  Abuse.prototype.send = function(name, data) {
    return this.socket.emit(name, data);
  };

  Abuse.prototype.setMap = function(data) {
    var layer, name, _ref,
      _this = this;
    this.map.width = data.width;
    this.map.height = data.height;
    if (this.map.stage) {
      this.nodes = {};
      this.map.stage.destroyChildren();
      this.map.stage.destroy();
      this.map.stage = null;
    }
    this.map.stage = new Kinetic.Stage({
      width: this.desktop.width,
      height: this.desktop.height,
      container: 'container'
    });
    this.map.stage.on('mousedown', function(e) {
      var angle, button, deltaX, deltaY, distance, node, offset, x, y, _ref;
      button = (_ref = e.button) != null ? _ref : 0;
      offset = $(_this.map.stage.content).offset();
      x = (e.clientX - offset.left) - _this.map.stage.getX();
      y = (e.clientY - offset.top) - _this.map.stage.getY();
      node = _this.nodes[_this.userStatus.nodes.player];
      deltaX = x - (node.x + (node.width / 2));
      deltaY = y - (node.y + (node.height / 2));
      angle = Math.atan2(deltaY, deltaX) * 180 / Math.PI;
      distance = Math.sqrt(Math.pow(deltaX, 2) + Math.pow(deltaY, 2));
      if (button === 0) {
        _this.sendKeys({
          fire: true
        }, {
          angle: angle,
          distance: distance
        });
      } else if (button === 2) {
        _this.sendKeys({
          fire2: true
        }, {
          angle: angle,
          distance: distance
        });
        return false;
      }
      return true;
    });
    this.map.layers.node = new Kinetic.Layer({
      name: 'node'
    });
    this.map.layers.player = new Kinetic.Layer({
      name: 'player'
    });
    _ref = this.map.layers;
    for (name in _ref) {
      layer = _ref[name];
      if (layer) {
        this.map.stage.add(layer);
      }
    }
    this.drawStart();
    return true;
  };

  /* 
    Spusteni prekreslovani canvasu, metoda se spusti po nastaveni mapy @setMap
    Pokud bezi je @isRunning true
  */


  Abuse.prototype.drawStart = function() {
    var index, tmp,
      _this = this;
    if (this.isRunning) {
      return false;
    }
    this.isRunning = true;
    index = 0;
    tmp = function() {
      var frame, layerName, _ref;
      _ref = _this.map.draw;
      for (layerName in _ref) {
        frame = _ref[layerName];
        if (_this.map.layers[layerName]) {
          if (index % frame === 0) {
            _this.drawLayer(layerName);
          } else if (_this.map.drawNow[layerName] === true) {
            _this.map.drawNow[layerName] = false;
            _this.drawLayer(layerName);
          }
        }
      }
      if (index % _this.map.deleteDraw === 0) {
        _this.collectDeleteNode();
      }
      index++;
      window.requestAnimationFrame(tmp);
      return true;
    };
    return window.requestAnimationFrame(tmp);
  };

  /*
    Prekresleni vrstvy v nasledujicim framu
  */


  Abuse.prototype.drawNow = function(layerName) {
    if (this.map.layers[layerName]) {
      return this.map.drawNow[layerName] = true;
    }
  };

  Abuse.prototype.remNode = function(id) {
    var layerName;
    if (this.nodes[id]) {
      layerName = this.nodes[id].getLayer().getName();
      this.nodes[id].destroy();
      this.drawNow(layerName);
      this.deleteNodeList.push(id);
      return console.log("MAZU ID: #" + id);
    }
  };

  Abuse.prototype.drawLayer = function(layerName) {
    this.map.layers[layerName].batchDraw();
    return true;
  };

  Abuse.prototype.collectDeleteNode = function() {
    var node_id, _i, _len, _ref;
    if (this.deleteNodeList.length === 0) {
      return false;
    }
    _ref = this.deleteNodeList;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node_id = _ref[_i];
      delete this.nodes[node_id];
    }
    this.deleteNodeList.length = 0;
    return true;
  };

  /*
    Pridani noveho objektu do platna
  */


  Abuse.prototype.setNodes = function(nodes) {
    var data, layer, _i, _len;
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      data = nodes[_i];
      if (!this.nodes[data.id]) {
        layer = this.getLayerByType(data.type);
        this.nodes[data.id] = this.createNode(data.type, data.id, layer);
        this.drawNow(layer.getName());
      }
      this.nodes[data.id].setData(data);
    }
    return this;
  };

  Abuse.prototype.setUserStatus = function(userStatus) {
    this.userStatus = userStatus;
    console.log("client.setUserStatus()", this.userStatus);
    return this;
  };

  Abuse.prototype.setWeaponStatus = function(weapon) {
    var _this = this;
    this.scope.$apply(function() {
      return _this.scope.weapons[weapon.slot] = weapon;
    });
    return console.log("client.setWeaponStatus(): ", weapon);
  };

  Abuse.prototype.setStatus = function(status) {
    var _this = this;
    this.status = status;
    this.scope.$apply(function() {
      return _this.scope.status = _this.status;
    });
    console.log("client.setStatus(): ", this.status);
    return this;
    return true;
  };

  Abuse.prototype.getLayerByType = function(type) {
    switch (type.toLowerCase()) {
      case "player":
      case "bullet":
      case "debug":
        return this.map.layers.player;
      default:
        return this.map.layers.node;
    }
  };

  Abuse.prototype.hightlightNode = function(node) {
    var tmp,
      _this = this;
    return false;
    tmp = function() {
      var animationStep, blur, clone, lastBlur, period, tmp2;
      clone = node.getObj().clone();
      clone.remove();
      _this.getLayerByType('debug').add(clone);
      clone.moveUp();
      period = 200;
      blur = 30;
      lastBlur = blur;
      clone.setShadowBlur(blur);
      tmp2 = function() {
        clone.setShadowBlur(0);
        return clone.destroy();
      };
      window.setTimeout(tmp2, 100);
      return true;
      return animationStep = function(frame) {
        var o;
        o = Math.floor(Math.min(frame.time, period) / period * 100);
        if (o !== lastBlur) {
          lastBlur = o;
          clone.setShadowBlur(blur - (blur / 100 * o));
        }
        if (frame.time > period) {
          clone.destroy();
          this.stop();
          return delete anim;
        }
      };
    };
    return window.setTimeout(tmp, 20);
  };

  Abuse.prototype.createNode = function(type, id, layer) {
    var node;
    node = false;
    switch (type.toLowerCase()) {
      case "rectangle":
        node = new Node.Rectangle(id, layer, this.scope);
        break;
      case "player":
        node = new Node.Player(id, layer, this.scope);
        break;
      case "bullet":
        node = new Node.Bullet(id, layer, this.scope);
        break;
      default:
        console.log("Chyba ! Neznam typ: " + type);
        node = new Node(id, layer, this.scope);
    }
    return node;
  };

  return Abuse;

})();

Node = (function() {
  function Node(id, layer, scope) {
    this.id = id;
    this.layer = layer;
    this.scope = scope;
    this.active = false;
    this.x = 0;
    this.y = 0;
    this.width = 0;
    this.height = 0;
    this.editMode = false;
    return true;
  }

  Node.prototype.setData = function(data) {
    this.x = data.x;
    this.y = data.y;
    this.width = data.width;
    this.height = data.height;
    return true;
  };

  Node.prototype.debugNode = function(obj) {
    var _this = this;
    obj.on('mouseenter', function() {
      return obj.setOpacity(0.7);
    });
    obj.on('mouseleave', function() {
      return obj.setOpacity(1);
    });
    obj.on('dragend', function() {
      console.log(obj.getX(), obj.getY());
      return console.log('dragend');
    });
    obj.on('dragstart', function() {
      _this.setEditMode(true);
      return console.log('START !');
    });
    return obj.setDraggable(true);
  };

  Node.prototype.destroy = function() {
    return true;
  };

  Node.prototype.setEditMode = function(editMode) {
    this.editMode = editMode;
  };

  Node.prototype.getObj = function() {
    var _ref;
    return (_ref = this.obj) != null ? _ref : false;
  };

  Node.prototype.getLayer = function() {
    return this.layer;
  };

  Node.prototype.getLayerName = function() {
    return this.layer.getName();
  };

  return Node;

})();

Node.Rectangle = (function(_super) {
  __extends(Rectangle, _super);

  function Rectangle() {
    Rectangle.__super__.constructor.apply(this, arguments);
    this.obj = new Kinetic.Rect({
      x: this.x,
      y: this.y,
      width: this.width,
      height: this.height,
      fill: '#aaa'
    });
    this.layer.add(this.obj);
  }

  Rectangle.prototype.setData = function(data) {
    Rectangle.__super__.setData.apply(this, arguments);
    if (this.editMode === false) {
      this.obj.move(data.x - this.obj.getX(), data.y - this.obj.getY());
      this.obj.setHeight(data.height);
      this.obj.setWidth(data.width);
    }
    return true;
  };

  Rectangle.prototype.destroy = function() {
    Rectangle.__super__.destroy.apply(this, arguments);
    return this.obj.destroy();
  };

  return Rectangle;

})(Node);

Node.Player = (function(_super) {
  __extends(Player, _super);

  function Player() {
    var img,
      _this = this;
    Player.__super__.constructor.apply(this, arguments);
    this.hp = -1;
    this.viewPort = {
      x: 0,
      y: 0,
      width: 100,
      height: 100
    };
    img = new Image();
    img.onerror = function() {
      return console.error("Chyba nacitani obrazku " + this.src);
    };
    img.onload = function() {
      _this.obj = new Kinetic.Rect({
        x: _this.x,
        y: _this.y,
        width: _this.width,
        height: _this.height,
        fill: 'magenta'
      });
      _this.layer.add(_this.obj);
      if (_this.obj.start) {
        return _this.obj.start();
      }
    };
    img.src = '/img/2_cop.png';
  }

  Player.prototype.setData = function(data) {
    var color;
    Player.__super__.setData.apply(this, arguments);
    this.hp = data.hp;
    this.viewPort = data.viewPort;
    if (this.obj && this.editMode === false) {
      this.obj.move(data.x - this.obj.getX(), data.y - this.obj.getY());
      this.obj.setHeight(data.height);
      this.obj.setWidth(data.width);
      color = [Number(Math.round(255 / 100 * (100 - this.hp))).toString(16), '00', '00'];
      if (color[0].length === 0) {
        color[0] = "0" + color[0];
      }
      this.obj.setFill(color.join(''));
    }
    return true;
  };

  Player.prototype.destroy = function() {
    Player.__super__.destroy.apply(this, arguments);
    return this.obj.destroy();
  };

  return Player;

})(Node);

Node.Bullet = (function(_super) {
  __extends(Bullet, _super);

  function Bullet() {
    Bullet.__super__.constructor.apply(this, arguments);
    this.obj = new Kinetic.Rect({
      x: this.x,
      y: this.y,
      width: this.width,
      height: this.height,
      fill: 'red'
    });
    window['OBJ'] = this.obj;
    this.layer.add(this.obj);
  }

  Bullet.prototype.setData = function(data) {
    Bullet.__super__.setData.apply(this, arguments);
    if (this.editMode === false) {
      this.obj.move(data.x - this.obj.getX(), data.y - this.obj.getY());
      this.obj.setHeight(data.height);
      this.obj.setWidth(data.width);
    }
    return true;
  };

  Bullet.prototype.destroy = function() {
    Bullet.__super__.destroy.apply(this, arguments);
    return this.obj.destroy();
  };

  return Bullet;

})(Node);

Abuse.$inject = ['$scope'];

app = angular.module('Abuse', []);

app.controller('Abuse', Abuse);

makeAnimation = function(w, h, rows, cols, opt) {
  var r, x, y, _i, _j;
  if (rows == null) {
    rows = 1;
  }
  if (cols == null) {
    cols = 1;
  }
  if (opt == null) {
    opt = {};
  }
  if (opt.last == null) {
    opt.last = 0;
  }
  if (opt.first == null) {
    opt.first = 0;
  }
  if (opt.x == null) {
    opt.x = 0;
  }
  if (opt.y == null) {
    opt.y = 0;
  }
  if (opt.xs == null) {
    opt.xs = 0;
  }
  if (opt.ys == null) {
    opt.ys = 0;
  }
  if (opt.cnt == null) {
    opt.cnt = 0;
  }
  r = [];
  for (y = _i = 0; 0 <= cols ? _i < cols : _i > cols; y = 0 <= cols ? ++_i : --_i) {
    for (x = _j = 0; 0 <= rows ? _j < rows : _j > rows; x = 0 <= rows ? ++_j : --_j) {
      r.push({
        width: w,
        height: h,
        x: w * (x + opt.xs),
        y: h * (y + opt.ys)
      });
    }
  }
  if (opt.first) {
    r = r.slice(opt.first);
  }
  if (opt.last) {
    r = r.slice(0, -opt.last);
  }
  if (opt.cnt) {
    r = r.slice(0, opt.cnt);
  }
  return r;
};
