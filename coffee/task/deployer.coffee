fs   = require 'fs'
path = require 'path'

Dependencies = require './dependencies'
config       = require './config'


class Deployer
  constructor: (@source) ->

  deploy: (callback) =>
    delete @error
    delete @deployed

    abbreviations =
      cs: 'css'
      ht: 'html'
      js: 'js'
    name = abbreviations[@constructor.name.toLowerCase().substr 0, 2]

    try
      unless config.deploy?[name]
        throw new Error 'No deploy.' + name + ' target found in config'

      dir = path.dirname config.deploy[name]
      Dependencies::mkdirp() dir, (err) =>
        if err
          @error = err
          callback? @error

        fs.writeFile config.deploy[name], @getSrc(), (err) =>
          if err
            @error = err
          else
            @deployed = true
          callback? @error

      @deployed = true
    catch err
      @error = err
      callback? @error

  getSrc: =>
    if @source.minifier?
      throw new Error(@source.minifier.error) if @source.minifier.error
      src = @source.minifier.src
    else if @source.concatenator?
      throw new Error(@source.concatenator.error) if @source.concatenator.error
      src = @source.concatenator.src
    else if @source.compiler?
      throw new Error(@source.compiler.error) if @source.compiler.error
      src = @source.compiler.src
    else
      throw new Error(@source.error) if @source.error
      src = @source.src

    throw new Error('Source is empty') unless src
    src

module.exports = Deployer
