fs = require 'fs'

md5 = require 'MD5'

Task = require '../task'


class Loader extends Task
  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err

      hash = md5 @_result or ''
      if hash isnt @hash or ''
        changed = true
      @hash = hash

      @status 1
      callback? err, changed

    try
      fs.readFile @source.path, encoding: 'utf8', (err, data) =>
        finish(err) if err
        @result data
        finish()
    catch err
      finish err

module.exports = Loader
