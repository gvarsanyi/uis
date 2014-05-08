HtmlFile  = require '../file/html'
JadeFile  = require '../file/jade'
Multi     = require '../task/multi'
Repo      = require '../repo'
config    = require '../config'
messenger = require '../messenger'


class HtmlRepo extends Repo
  extensions: {html: HtmlFile, jade: JadeFile}

  getTasks: ->
    tasks = compiler: new Multi @, 'compiler'

    if config.deploy?.html
      tasks.deployer = new Multi @, 'deployer'

    if config.minifiedDeploy?.html
      tasks.minifier         = new Multi @, 'minifier'
      tasks.minifiedDeployer = new Multi @, 'minifiedDeployer'

    tasks

module.exports = new HtmlRepo

messenger module.exports
