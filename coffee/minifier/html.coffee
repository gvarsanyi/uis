Dependencies = require '../dependencies'
Minifier     = require '../minifier'


class HtmlMinifier extends Minifier
  minify: (callback) =>
    delete @error
    delete @src

    try
      @src = Dependencies::htmlminify().minify @source.src,
        removeComments:               true
        removeCommentsFromCDATA:      true
        removeCDATASectionsFromCDATA: true
        collapseWhitespace:           true
        collapseBooleanAttributes:    true
        removeRedundantAttributes:    true
        useShortDoctype:              true
        removeEmptyAttributes:        true
        removeOptionalTags:           true
    catch err
      @error = err
#       console.error '\nHTML MINIFY ERROR', @source.path, err

    callback? @error, @src

module.exports = HtmlMinifier
