fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Task = require '../task'


class Deployer extends Task
  constructor: (@source, @deployTarget, @minified) ->
    @_tasks = ['concatenator', 'compiler', 'loader']
    if @minified
      @_tasks.unshift 'minifier'

  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err
      @status 1
      callback? err

    try
      abbreviations =
        cs: 'css'
        ht: 'html'
        js: 'js'
      name = abbreviations[@source.constructor.name.toLowerCase().substr 0, 2]

      dir = path.dirname @deployTarget
      mkdirp dir, (err) =>
        return finish(err) if err

        fs.writeFile @deployTarget, @getSrc(), finish
    catch err
      finish err

  getSrc: =>
    for task in @_tasks
      if @source.tasks[task]?
        unless (src = @source.tasks[task].result())?
          throw new Error '[Deployer] Missing source'

        return src

    throw new Error '[Deployer] Source is empty'

module.exports = Deployer
