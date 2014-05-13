Task = require '../task'


class Concatenator extends Task
  name: 'concatenator'

  followUp: =>
    @source.tasks.deployer.work()
    @source.tasks.minifier.work()

  work: => @preWork arguments, (callback) =>
    try
      concatenated = ''
      for path, source of @source.sources
        if source.compilable
          src = source.compiled
        else
          src = source.data

        unless src?
          throw new Error '[Concatenator] Missing source: ' + source.path

        concatenated += src + '\n\n'

      callback null, concatenated
    catch err
      callback err

module.exports = Concatenator
