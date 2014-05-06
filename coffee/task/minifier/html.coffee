htmlminify = require 'html-minifier'

Minifier = require '../minifier'


class HtmlMinifier extends Minifier
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.compiler?.result())?
        unless (src = @source.tasks.loader.result())?
          throw new Error '[CssMinifier] Missing source: ' + @source.path

      @result htmlminify.minify src,
        removeComments:               true
        removeCommentsFromCDATA:      true
        removeCDATASectionsFromCDATA: true
        collapseWhitespace:           true
        collapseBooleanAttributes:    true
        removeRedundantAttributes:    true
        useShortDoctype:              true
        removeEmptyAttributes:        true
    catch err
      @error err

    @status 1
    callback?()

module.exports = HtmlMinifier
