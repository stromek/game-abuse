rbush =  require('./rbush/rbush.js')

class Connector
  constructor : () ->
    @tree = rbush(9)

  insert : (x, y, width, height, data = {}) ->
    @tree.insert [Math.max(x, 0), Math.max(y, 0), x + width, y + height, data]


  clear : () ->
    @tree.clear()

  search : (x, y, width, height) ->
    return @tree.search [x, y, x + width, y + height]


module.exports = Connector