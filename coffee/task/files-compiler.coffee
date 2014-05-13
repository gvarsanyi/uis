FilesTask = require '../files-task'


class FilesCompiler extends FilesTask
  name:           'filesCompiler'
  sourceProperty: 'compiled'

  followUp: =>
    @source.tasks.concatenator?.work() unless @source.name is 'js'
    @source.tasks.filesDeployer?.work()
    @source.tasks.filesMinifier?.work()

  fileCondition: (source) ->
    !!source.compilable

module.exports = FilesCompiler
