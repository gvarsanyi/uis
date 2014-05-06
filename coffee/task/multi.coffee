Task = require '../task'


class Multi extends Task
  constructor: (@source, @taskName) ->
    @path = @source.path

  count: ->
    i = 0
    for path, source of @source.sources
      if source.tasks[@taskName]
        i += 1
    i

  error: ->
    for path, source of @source.sources
      if add = source.tasks[@taskName]?.error()
        @_error ?= []
        @_error.push add
    @_error

  warning: ->
    for path, source of @source.sources
      if add = source.tasks[@taskName]?.warning()
        @_warning ?= []
        @_warning.push add
    @_warning

  result: -> @_result # undefined

  size: ->
    total = null
    for path, source of @source.sources
      if (size = source.tasks[@taskName]?.size())?
        total ?= 0
        total += size
    total

  status: ->
    count = undefined
    for path, source of @source.sources
      switch source.tasks[@taskName]?.status()
        when 1
          count ?= 0
          count += 1
        when 0
          count ?= 0
    count

  work: (callback) ->
    sources = for path, source of @source.sources when source.tasks[@taskName]
      source

    callback?() unless sources.length

    done = 0
    finished = ->
      done += 1
      if done is sources.length
        callback?()

    for source in sources
      source.tasks[@taskName].work finished

module.exports = Multi
