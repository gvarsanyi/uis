FilesTask = require '../files-task'


class FilesMinifier extends FilesTask
  name:           'filesMinifier'
  sourceProperty: 'minified'

  followUp: (node) =>
    @source.tasks.filesDeployer.work node

  fileCondition: (source) ->
    source.options.minify and not source.options.testOnly

module.exports = FilesMinifier
