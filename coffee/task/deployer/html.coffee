fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Deployer = require '../deployer'


class HtmlDeployer extends Deployer
  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err
      @status 1
      callback? err

    try
      unless basedir = @source.options.basedir
        throw new Error 'Missing basedir'
      unless @source.path.substr(0, basedir.length) is basedir
        throw new Error ' Path (\'' + @source.path + '\' does not begin with ' +
                        ' basedir: \'' + basedir + '\''

      out = @deployTarget + @source.path.substr basedir.length
      if out.toLowerCase().substr(out.length - 5) is '.jade'
        out = out.substr(0, out.length - 4) + 'html'

      mkdirp path.dirname(out), null, (err) =>
        return finish(err) if err
        fs.writeFile out, @getSrc(), finish
    catch err
      finish err

module.exports = HtmlDeployer
