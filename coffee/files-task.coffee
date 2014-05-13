Task      = require './task'
messenger = require './messenger'


class FilesTask extends Task
  clear: (callback) =>
    super()
    delete @_count
    callback?()

  work: (callback) =>
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
      @followUp?()

    finished_file = =>
      done += 1
      if done is count
        callback? @error()
        messenger.sendStat @name
        @followUp?()

    for source in sources
      delete source[@sourceProperty] if @sourceProperty?
      @workFile source, finished_file

  preWorkFile: (args, work_file) =>
    source   = args[0]
    callback = args[1]

    post_work_file = =>
      @status @status() + 1
      callback()

    work_file source, post_work_file

module.exports = FilesTask
