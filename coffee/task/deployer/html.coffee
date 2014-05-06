fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Deployer = require '../deployer'
config   = require '../../config'


class HtmlDeployer extends Deployer
  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err
      @status 1
      callback?()

    try
      unless config.deploy?.html
        throw new Error 'No deploy.html target found in config'

      target = config.deploy.html + @source.path.substr @source.basedir.length
      if target.toLowerCase().substr(target.length - 5) is '.jade'
        target = target.substr(0, target.length - 4) + 'html'

      mkdirp path.dirname(target), null, (err) =>
        return finish(err) if err
        fs.writeFile target, @getSrc(), finish
    catch err
      finish err


module.exports = HtmlDeployer
