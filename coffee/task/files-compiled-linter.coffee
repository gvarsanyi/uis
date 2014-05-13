FilesTask = require '../files-task'


class FilesLinter extends FilesTask
  name: 'filesCompiledLinter'

  fileCondition: (source) ->
    source.compilable and not source.options.thirdParty and not source.options.testOnly

module.exports = FilesLinter
