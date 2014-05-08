jade = require 'jade'


jade.Parser::_parseInclude = jade.Parser::parseInclude
jade.Parser::parseInclude = ->
  if (list = @options?.includes) and typeof list is 'object'
    tok  = @peek()
    path = @resolvePath tok.val.trim(), 'include'

    p = require 'path'
    file = p.resolve @filename
    path = p.resolve path

    if list instanceof Array
      for item in list
        if item is path
          return @_parseInclude()
      list.push path
    else
      list[file] ?= {}
      list[file][path] ?= []
      list[file][path].push tok.line

  @_parseInclude()
