fs   = require 'fs'
path = require 'path'

Dependencies = require '../dependencies'
Deployer     = require '../deployer'
config       = require '../config'


class HtmlDeployer extends Deployer
  deploy: (callback) =>
    delete @error
    delete @deployed

    try
      unless config.deploy?.html
        throw new Error 'No deploy.html target found in config'

      target = config.deploy.html + @source.path.substr @source.basedir.length
      if target.toLowerCase().substr(target.length - 5) is '.jade'
        target = target.substr(0, target.length - 4) + 'html'

      Dependencies::mkdirp() path.dirname(target), null, (err) =>
        if err
          @error = err
          callback? @error

        fs.writeFile target, @getSrc(), (err) =>
          if err
            @error = err
          else
            @deployed = true
          callback? @error

      @deployed = true
    catch err
      @error = err
      callback? @error

module.exports = HtmlDeployer
