cssminify = require 'clean-css'

Minifier = require '../minifier'


class CssMinifier extends Minifier
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.concatenator.result())?
        throw new Error '[CssMinifier] Missing source: ' + @source.path

      minifier = new cssminify keepSpecialComments: 0
      @result minifier.minify src or ''
    catch err
      @error err

    @status 1
    callback?()

module.exports = CssMinifier
