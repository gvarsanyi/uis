jsminify = require 'uglify-js'

Minifier = require '../minifier'


class JsMinifier extends Minifier
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.concatenator.result())?
        throw new Error '[CssMinifier] Missing source: ' + @source.path

      @result jsminify.minify(src, fromString: true).code
    catch err
      @error err

    @status 1
    callback? err

module.exports = JsMinifier
