htmlminify = require 'html-minifier'

FilesMinifier = require '../files-minifier'


class HtmlFilesMinifier extends FilesMinifier
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      unless src = source[if @source.tasks.filesCompiler? then 'compiled' else 'data']
        throw new Error '[HtmlFilesMinifier] Missing source: ' + source.path

      source[@sourceProperty] = htmlminify.minify src,
        removeComments:               true
        removeCommentsFromCDATA:      true
        removeCDATASectionsFromCDATA: true
        collapseWhitespace:           true
        collapseBooleanAttributes:    true
        removeRedundantAttributes:    true
        useShortDoctype:              true
        removeEmptyAttributes:        true
    catch err
      @error err, source

    callback()

module.exports = HtmlFilesMinifier
