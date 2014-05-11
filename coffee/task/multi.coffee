Task = require '../task'


class Multi extends Task
  constructor: (source, @taskName) ->
    super source
    @path = @source.path

  count: ->
    i = 0
    for path, source of @source.sources
      if source.tasks[@taskName]
        i += 1
    i

  error: ->
    value = undefined
    for path, source of @source.sources
      if add = source.tasks[@taskName]?.error()
        value ?= []
        value.push add
    value

  warning: ->
    value = undefined
    for path, source of @source.sources
      if add = source.tasks[@taskName]?.warning()
        value ?= []
        value.push add
    value

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

  updatedAt: ->
    latest = 0
    for path, source of @source.sources
      if latest < t = source.tasks[@taskName]?.updatedAt()
        latest = t
    latest

  watched: ->
    i = null
    for path, source of @source.sources
      if (n = source.tasks[@taskName]?.watched())?
        i ?= 0
        i += n
    i

  work: (callback) ->
    sources = for path, source of @source.sources when source.tasks[@taskName]
      source

    callback?() unless sources.length

    done = 0
    errors = undefined
    finished = (err) ->
      if err
        errors ?= []
        errors.push err

      done += 1
      if done is sources.length
        callback? errors

    for source in sources
      source.tasks[@taskName].work finished

module.exports = Multi
