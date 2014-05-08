coffeelint = require 'coffeelint'

Linter = require '../linter'


class CoffeeLinter extends Linter
  work: (callback) => @clear =>
    @status 0

    try
      unless (src = @source.tasks.loader.result())?
        throw new Error '[CoffeeLinter] Missing source'

      for msg in coffeelint.lint src
        if msg.level is 'error'
          @error msg
        else
          @warning msg
    catch err
      @error err

    @status 1
    callback? err

module.exports = CoffeeLinter
