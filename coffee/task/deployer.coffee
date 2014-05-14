fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Task   = require '../task'
config = require '../config'


class Deployer extends Task
  name: 'deployer'

  work: => @preWork arguments, (callback) =>
    try
      if config[@source.name].minify
        src = @source.tasks.minifier.result()
      else
        src = @source.tasks.concatenator.result()

      unless src
        throw new Error '[Deployer] Missing source'

      target = config[@source.name].deploy
      mkdirp path.dirname(target), (err) =>
        return callback(err) if err

        fs.writeFile target, src, (err) =>
          callback err
    catch err
      callback err

module.exports = Deployer
