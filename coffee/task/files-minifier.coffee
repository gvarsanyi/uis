FilesTask = require '../files-task'


class FilesMinifier extends FilesTask
  name:           'filesMinifier'
  sourceProperty: 'minified'

  followUp: (node) =>
    @source.tasks.filesMinifiedDeployer.work node

  fileCondition: (source) ->
    source.options.deployMinified and not source.options.testOnly

module.exports = FilesMinifier
