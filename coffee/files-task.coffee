Task      = require './task'
messenger = require './messenger'


class FilesTask extends Task
  clear: (callback) =>
    super()
    delete @_count
    callback?()

  work: (node, callback) =>
    if typeof node is 'function'
      callback = node
      node = undefined

    if node
      work_file_done = =>
        messenger.sendStat @name
        @followUp?(node) unless @error()
        @source.checkAllTasksFinished()

      return @workFile node, work_file_done, true

    sources = []
    for path, source of @source.sources
      if not @fileCondition? or @fileCondition source
        sources.push source

    @clear()
    @count(count = sources.length)
    @status(done = 0)

    messenger.sendStat @name
    unless count
      callback?()
      @followUp?(node) unless @error()
      return @source.checkAllTasksFinished()

    finished_file = =>
      done += 1
      if done is count
        callback? @error()
        messenger.sendStat @name
        @followUp?(node) unless @error()
        @source.checkAllTasksFinished()

    for source in sources
      delete source[@sourceProperty] if @sourceProperty?
      @status @status() + 1
      @workFile source, finished_file

  preWorkFile: (args, work_file) =>
    source   = args[0]
    callback = args[1]

    for underscored in ['_error', '_warning']
      if source[underscored]?
        delete source[underscored][@name]

    unless not @fileCondition? or @fileCondition source
      return callback()

    @status @status() - 1
    messenger.sendStat(@name) if args[2]

    post_work_file = (pass_back...) =>
      @status @status() + 1
      if pass_back?.length
        callback pass_back...
      else
        callback()

    work_file source, post_work_file

module.exports = FilesTask
