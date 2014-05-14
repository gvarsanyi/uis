FilesDeployer     = require '../task/files-deployer'
HtmlFile          = require '../file/html'
HtmlFilesMinifier = require '../task/files-minifier/html'
JadeFilesCompiler = require '../task/files-compiler/jade'
JadeFile          = require '../file/jade'
Repo              = require '../repo'
config            = require '../config'
messenger         = require '../messenger'


class HtmlRepo extends Repo
  extensions: {html: HtmlFile, jade: JadeFile}

  getTasks: ->
    filesCompiler: new JadeFilesCompiler @
    filesMinifier: new HtmlFilesMinifier @
    filesDeployer: new FilesDeployer @

module.exports = new HtmlRepo

messenger module.exports
