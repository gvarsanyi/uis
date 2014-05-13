Task   = require '../task'
config = require '../config'


class Minifier extends Task
  name: 'minifier'

  followUp: =>
    @source.tasks.minifiedDeployer.work()

  condition: =>
    !!config[@source.name].deployMinified

module.exports = Minifier
