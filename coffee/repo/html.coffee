HtmlFile  = require '../file/html'
JadeFile  = require '../file/jade'
Multi     = require '../task/multi'
Repo      = require '../repo'
messenger = require '../messenger'


class HtmlRepo extends Repo
  extensions: {html: HtmlFile, jade: JadeFile}

  constructor: ->
    @tasks =
      loader:   new Multi @, 'loader'
      compiler: new Multi @, 'compiler'
      minifier: new Multi @, 'minifier'
      deployer: new Multi @, 'deployer'
    super

module.exports = new HtmlRepo

messenger module.exports
