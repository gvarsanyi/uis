karma = require 'karma'


done    = false
started = false
process.on 'message', (options) ->
  return if started
  started = true

  karma.server.start options, (exit_code) =>
    done = true
    setTimeout ->
      process.exit exit_code
    , 10

process.send 'ready'
