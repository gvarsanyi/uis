fs = require 'fs'


class File
  constructor: (@repo, @path, @basedir) ->
    fs.readFile @path, encoding: 'utf8', (err, data) =>
      return console.error(err) if err
      @src = data
      @loaded = true

      compile = =>
        @compiler?.compile(minify) or minify()

      minify = =>
        @minifier?.minify(deploy) or deploy()

      deploy = =>
        @deployer?.deploy(@repo.check) or @repo.check()

      if @constructor.name is 'CoffeeFile' # compiling the concatenated repo
        @repo.check()                      # for js/coffee is higher priority
        @compiler?.compile()               # then per-file compilation
      else
        compile()

module.exports = File
