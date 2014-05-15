htmlminify = require 'html-minifier'

FilesMinifier = require '../files-minifier'


class HtmlFilesMinifier extends FilesMinifier
  workFile: => @preWorkFile arguments, (source, callback) =>
    try
      if source.compilable
        src = source.compiled
      else
        src = source.data

      unless src?
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
