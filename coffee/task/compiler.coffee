fs = require 'fs'

gaze = require 'gaze'
md5  = require 'MD5'

Task = require '../task'


class WatchedFile
  constructor: (@compiler, @path) ->
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      @hash = md5 data

  changed: (callback) =>
    fs.readFile @path, encode: 'utf8', (err, data='') =>
      if @hash isnt hash = md5 data
        @hash = hash
        callback?()

class Compiler extends Task
  constructor: (@source) ->
    @_watched = {}

  watch: (watchables=[], callback) =>
    try
      for k of @_watched
        delete @_watched[k]
      @_gaze.close() if @_gaze
      delete @_watching
      for watchable in watchables
        @_watched[watchable] = new WatchedFile @, watchable

      updated = (event, file) =>
        @_watched[file]?.changed =>
          @source.repo.fileUpdate 'changed', @source.path, true

      gaze_error = null
      if watchables.length
        @_gaze = new gaze
        @_gaze.on 'all', updated
        @_gaze.on 'error', (err) ->
          gaze_error = err
        @_gaze.on 'ready', ->
          callback? gaze_error
        @_gaze.add watchables

        @_watching = true
      else
        delete @_gaze
    catch err
      callback? err

module.exports = Compiler
