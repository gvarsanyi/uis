fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Task   = require '../task'
config = require '../config'


class Deployer extends Task
  name: 'deployer'

  work: => @preWork arguments, (callback) =>
    try
      target = config[@source.name].deploy
      mkdirp path.dirname(target), (err) =>
        return callback(err) if err

        fs.writeFile target, @source.tasks.concatenator.result(), (err) =>
          callback err
    catch err
      callback err

module.exports = Deployer
