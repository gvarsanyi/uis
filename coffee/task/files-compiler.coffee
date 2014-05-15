FilesTask = require '../files-task'


class FilesCompiler extends FilesTask
  name:           'filesCompiler'
  sourceProperty: 'compiled'

  followUp: (node) =>
    @source.tasks.concatenator?.work node
    @source.tasks.filesMinifier?.work node
    @source.tasks.filesLinter?.work node

  fileCondition: (source) ->
    !!source.compilable

module.exports = FilesCompiler
