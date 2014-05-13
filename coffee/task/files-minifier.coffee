FilesTask = require '../files-task'


class FilesMinifier extends FilesTask
  name:           'filesMinifier'
  sourceProperty: 'minified'

  followUp: =>
    @source.tasks.filesMinifiedDeployer.work()

  fileCondition: (source) ->
    source.options.deployMinified and not source.options.testOnly

module.exports = FilesMinifier
