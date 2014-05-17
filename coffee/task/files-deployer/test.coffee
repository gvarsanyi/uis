FilesDeployer = require '../files-deployer'


class TestFilesDeployer extends FilesDeployer
  fileCondition: (source) ->
    true

  followUp: (node) =>
    @source.tasks.tester?.work node

  workFile: (source) =>
    source.options.basedir = @source.projectPath
    source.options.deploy  = @source.repoTmp + 'clone'
    super

module.exports = TestFilesDeployer
