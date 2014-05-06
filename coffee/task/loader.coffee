fs = require 'fs'

Task = require '../task'


class Loader extends Task
  constructor: (@source) ->

  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err
      @status 1
      callback?()

    try
      fs.readFile @path, encoding: 'utf8', (err, data) =>
        return finish(err) if err
        @result data
        @status 1
        callback?()
    catch err
      finish err

module.exports = Loader
