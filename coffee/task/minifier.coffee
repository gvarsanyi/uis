Task   = require '../task'
config = require '../config'


class Minifier extends Task
  name: 'minifier'

  followUp: (node) =>
    @source.tasks.deployer.work node

  condition: =>
    !!config[@source.name].minify

module.exports = Minifier
