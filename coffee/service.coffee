fs        = require 'fs'
path      = require 'path'

express   = require 'express'
faye      = require 'faye'
restify   = require 'restify'

config    = require './config'
messenger = require './messenger'


app    = express()
bayeux = null
server = null

plugin = fs.readFileSync(__dirname + '/../node_modules/faye/browser/' +
                         'faye-browser-min.js', encoding: 'utf8') + '\n\n' +
         fs.readFileSync __dirname + '/../service-plugin.js', encoding: 'utf8'

class Service
  name: 'web-service'

  constructor: ->
    app.use (req, res, next) -> # log
      messenger.note req.method + ' ' + req.url +
                     if req.body? then ' ' + JSON.stringify(req.body) else ''
      next()

    process.on 'uncaughtException', (err) ->
      switch err.code
        when 'EADDRINUSE'
          messenger.note 'port ' + config.service.port + ' is already in use'
        when 'EACCES'
          msg = config.service.port
          unless process.getuid() is 0 or config.service.port > 1023
            msg += ' (you need root permissions)'
          messenger.note 'No permission to open port ' + msg
        else
          messenger.note 'server error: ' + err
      process.exit 1

    app.get '/healthcheck', (req, res) ->
      res.type 'json'
      res.json 200,
        name:        process.cwd().split('/').pop()
        memory:      process.memoryUsage()
        uptime:      Math.round(process.uptime() * 1000) / 1000
        server:
          interface: config.service.interface
          port:      config.service.port
        system:
          platform:     process.platform
          architecture: process.arch

    contents = path.resolve config.service.contents
    patch_js = (deploy) ->
      deploy = path.resolve deploy
      if deploy.substr(0, contents.length) is contents
        app.get deploy.substr(contents.length), (req, res) ->
          fs.readFile deploy, encoding: 'utf8', (err, data) ->
            if err
              res.type 'json'
              res.json 500, error: 'Server Error: loading ' + deploy
            else
              res.send plugin + '\n\n' + data
    patch_js(deploy) if deploy = config.js?.deploy
    patch_js(deploy) if deploy = config.js?.deployMinified

    app.use express.static config.service.contents

    if config.service.proxy
      unless config.service.proxy instanceof Array
        config.service.proxy = [config.service.proxy]

      for proxy in config.service.proxy
        do (proxy) ->
          app.all proxy.pattern, (req, res) ->
            url = proxy.target
            if url.substr(url.length - 1) is '/'
              url = url.substr 0, url.length - 1
            url += req.url

            handler = (err, preq, pres, data) ->
              res.type 'json'
              try
                messenger.note '[proxy response] ' + (pres?.statusCode or '?') +
                              ' ' + req.method + ' ' + url
                res.json pres?.statusCode, data
              catch
                try res.json 500, error: 'Server Error', data

            client = restify.createJsonClient {url}
            messenger.note '[proxy request] ' + req.method + ' ' + url

            method = req.method.toLowerCase().replace 'delete', 'del'
            switch req.method
              when 'POST', 'PUT'
                client[method] url, req.body, handler
              else
                client[method] url, handler

    server = app.listen config.service.port, config.service.interface, ->
      bayeux = new faye.NodeAdapter mount: '/bayeux'
      bayeux.attach server

      bayeux.on 'subscribe', (client_id, channel) ->
        messenger.note '[client subscription] ' + client_id + ': ' + channel

      messenger.note 'listening @ ' + config.service.interface + ':' +
                     config.service.port

  publish: (channel, message) ->
    messenger.note '[bayeux] ' + channel + ': ' + JSON.stringify message
    bayeux_server.getClient().publish channel, message


module.exports = new Service

messenger module.exports
