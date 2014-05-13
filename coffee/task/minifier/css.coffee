cssminify = require 'clean-css'

Minifier = require '../minifier'


class CssMinifier extends Minifier
  work: => @preWork arguments, (callback) =>
    try
      unless (src = @source.tasks.concatenator.result())?
        throw new Error '[CssMinifier] Missing source'

      minifier = new cssminify keepSpecialComments: 0
      callback null, minifier.minify src or ''
    catch err
      callback err

module.exports = CssMinifier
