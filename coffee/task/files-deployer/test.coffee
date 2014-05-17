FilesDeployer = require '../files-deployer'


class TestFilesDeployer extends FilesDeployer
  fileCondition: (source) ->
    not source.options.thirdParty

  followUp: (node) =>
    @source.tasks.tester?.work node

  workFile: (source) =>
    if source.path.substr(0, @source.projectPath.length) is @source.projectPath
      path = @source.repoTmp + 'clone/' + source.path.substr @source.projectPath.length
    else
      path = @source.repoTmp + 'clone' + source.path
    source.options.basedir = @source.projectPath
    source.options.deploy  = path
    super

module.exports = TestFilesDeployer
