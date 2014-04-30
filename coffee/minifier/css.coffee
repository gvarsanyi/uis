Dependencies = require '../dependencies'
Minifier     = require '../minifier'


class CssMinifier extends Minifier
  minify: (callback) =>
    delete @error
    delete @src

    try
      src = @source.concatenator?.src or @source.compiler?.src or @source.src
      throw new Error('No source found') unless src
      minifier = new Dependencies::cssminify() keepSpecialComments: 0
      @src = minifier.minify src or ''
    catch err
      @error = err
#       console.error '\nCSS MINIFY ERROR', @source.path, err

    callback? @error, @src

module.exports = CssMinifier
