FilesTask = require '../files-task'


class FilesCompiler extends FilesTask
  name:           'filesCompiler'
  sourceProperty: 'compiled'

  fileCondition: (source) ->
    !!source.compilable and (not source.options.testOnly or @source.name is 'test')

  followUp: (node) =>
    @source.tasks.concatenator?.work node
    @source.tasks.filesMinifier?.work node
    @source.tasks.filesLinter?.work node
    @source.tasks.filesDeployer?.work(node) if @source.name is 'test'

module.exports = FilesCompiler
