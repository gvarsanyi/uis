jsminify = require 'uglify-js'

Minifier = require '../minifier'


class JsMinifier extends Minifier
  work: => @preWork arguments, (callback) =>
    try
      unless (src = @source.tasks.concatenator.result())?
        throw new Error '[JsMinifier] Missing source'

      callback null, jsminify.minify(src, fromString: true).code
    catch err
      callback err

module.exports = JsMinifier
