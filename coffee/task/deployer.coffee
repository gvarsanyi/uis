fs   = require 'fs'
path = require 'path'

mkdirp = require 'mkdirp'

Task   = require '../task'
config = require '../config'


class Deployer extends Task
  constructor: (@source) ->

  work: (callback) => @clear =>
    @status 0

    finish = (err) =>
      @error(err) if err
      @status 1
      callback?()

    try
      abbreviations =
        cs: 'css'
        ht: 'html'
        js: 'js'
      name = abbreviations[@source.constructor.name.toLowerCase().substr 0, 2]

      unless config.deploy?[name]
        throw new Error 'No deploy.' + name + ' target found in config'

      dir = path.dirname config.deploy[name]
      mkdirp dir, (err) =>
        return finish(err) if err

        fs.writeFile config.deploy[name], @getSrc(), finish
    catch err
      finish err

  getSrc: =>
    for task in ['minifier', 'concatenator', 'compiler', 'loader']
      if @source.tasks[task]?
        unless (src = @source.tasks[task].result())?
          throw new Error '[Deployer] Missing source'

        return src

    throw new Error '[Deployer] Source is empty'

module.exports = Deployer
