Dependencies = require './Dependencies'
Minifier     = require './Minifier'


class JsMinifier extends Minifier
  minify: (callback) =>
    delete @error
    delete @src

    try
      src = @source.concatenator?.src or @source.compiler?.src or @source.src
      throw new Error('No source found') unless src
      @src = Dependencies::jsminify().minify(src, fromString: true).code
    catch err
      @error = err
      console.error '\nJS MINIFY ERROR', @source.path, err

    callback? @error, @src

module.exports = JsMinifier
