
class Task
  clear: (callback) ->
    delete @_error
    delete @_warning
    delete @_result
    delete @_status
    callback?()

  count: -> 1 # for compatibility with MultifileTask

  error: (add) ->
    if add?
      @_error ?= []
      @_error.push add
    @_error

  warning: (add) ->
    if add?
      @_warning ?= []
      @_warning.push add
    @_warning

  result: (value) ->
    @_result = value if value?
    @_result

  size: ->
    if typeof @_result is 'string'
      return @_result.length
    null

  status: (value) ->
    if value?
      @_status = value
      @_updatedAt = new Date().getTime()
    @_status

  updatedAt: ->
    @_updatedAt ?= new Date().getTime()

  watched: ->
    i = null
    for k of @_watched or {}
      i ?= 0
      i += 1
    i

  work: (callback) ->  # should be overridden by all classes inherited from Task
    throw new Error 'Task.work() is not implemented for ' + @constructor.name


module.exports = Task
