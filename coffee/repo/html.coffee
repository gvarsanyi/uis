FilesDeployer         = require '../task/files-deployer'
FilesMinifiedDeployer = require '../task/files-minified-deployer'
HtmlFile              = require '../file/html'
HtmlFilesMinifier     = require '../task/files-minifier/html'
JadeFilesCompiler     = require '../task/files-compiler/jade'
JadeFile              = require '../file/jade'
Repo                  = require '../repo'
config                = require '../config'
messenger             = require '../messenger'


class HtmlRepo extends Repo
  extensions: {html: HtmlFile, jade: JadeFile}

  getTasks: ->
    filesCompiler:         new JadeFilesCompiler @
    filesDeployer:         new FilesDeployer @
    filesMinifier:         new HtmlFilesMinifier @
    filesMinifiedDeployer: new FilesMinifiedDeployer @

module.exports = new HtmlRepo

messenger module.exports
