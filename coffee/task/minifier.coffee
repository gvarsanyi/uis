Task   = require '../task'
config = require '../config'


class Minifier extends Task
  name: 'minifier'

  followUp: (node) =>
    @source.tasks.minifiedDeployer.work node

  condition: =>
    !!config[@source.name].deployMinified

module.exports = Minifier
