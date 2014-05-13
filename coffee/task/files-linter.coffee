FilesTask = require '../files-task'


class FilesLinter extends FilesTask
  name: 'filesLinter'

  fileCondition: (source) ->
    not source.compilable and not source.options.thirdParty and not source.options.testOnly

module.exports = FilesLinter
