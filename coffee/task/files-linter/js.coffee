jslint = require 'jslint'

FilesLinter = require '../files-linter'


class JsFilesLinter extends FilesLinter
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless (src = source.data)?
        throw new Error '[JsFilesLinter] Missing source: ' + source.path

      (worker = jslint.load 'latest') src

      for msg in worker.errors
        @warning msg
    catch err
      @error err

    callback()

module.exports = JsFilesLinter
