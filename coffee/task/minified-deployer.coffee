fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Task   = require '../task'
config = require '../config'


class MinifiedDeployer extends Task
  name: 'minifiedDeployer'

  followUp: =>
    @source.tasks.tester?.work()

  condition: =>
    !!config[@source.name].deployMinified

  work: => @preWork arguments, (callback) =>
    try
      target = config[@source.name].deployMinified
      mkdirp path.dirname(target), (err) =>
        if err
          @error err
          return callback()

        fs.writeFile target, @source.tasks.minifier.result(), (err) =>
          @error(err) if err
          callback()
    catch err
      @error err
      callback()

module.exports = MinifiedDeployer
