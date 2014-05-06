
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
    @_status = value if value?
    @_status

  work: (callback) ->  # should be overridden by all classes inherited from Task
    callback?()


module.exports = Task
