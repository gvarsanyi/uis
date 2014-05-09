HtmlFile  = require '../file/html'
JadeFile  = require '../file/jade'
Multi     = require '../task/multi'
Repo      = require '../repo'
config    = require '../config'
messenger = require '../messenger'


class HtmlRepo extends Repo
  extensions: {html: HtmlFile, jade: JadeFile}

  getTasks: ->
    for inf in @dirs
      if inf.deploy
        deploy = true
      if inf.deployMinified
        deploy_minified = true

    tasks = compiler: new Multi @, 'compiler'

    if deploy
      tasks.deployer = new Multi @, 'deployer'

    if deploy_minified
      tasks.minifier         = new Multi @, 'minifier'
      tasks.minifiedDeployer = new Multi @, 'minifiedDeployer'

    tasks

module.exports = new HtmlRepo

messenger module.exports
