# coffee = require 'coffee-script'

Concatenator = require '../concatenator'

# TODO: instead of recompiling in blocks, bundle the followings:
# var local_vars...,
#   __slice = [].slice,
#   __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
#   __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
#   __hasProp = {}.hasOwnProperty,
#   __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

class JsConcatenator extends Concatenator

# version with combined concatenator/compiler
#   work: => @preWork arguments, (callback) =>
#     try
#       parts = []
#       for path, source of @source.sources
#         unless part?.compiled is compiled = source.constructor.name is 'CoffeeFile'
#           parts.push part = {compiled, src: ''}
#
#         unless source.data?
#           throw new Error '[JsConcatenator] Missing source: ' + source.path
#
#         part.src += source.data + '\n\n'
#
#       concatenated = ''
#       for part in parts
#         if part.compiled
#           concatenated += coffee.compile part.src, bare: true
#         else
#           concatenated += part.src
#
#       callback null, concatenated
#     catch err
#       callback err

module.exports = JsConcatenator
