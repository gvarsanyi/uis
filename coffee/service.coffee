fs        = require 'fs'
path      = require 'path'

express   = require 'express'
faye      = require 'faye'
restify   = require 'restify'

config    = require './config'
messenger = require './messenger'
stats     = require './stats'


app    = express()
bayeux = null
server = null

patch = fs.readFileSync(__dirname + '/../node_modules/faye/browser/' +
                        'faye-browser.js', encoding: 'utf8') + '\n'
patch = patch.replace '//@ sourceMappingURL=faye-browser-min.js.map', ''
patch += fs.readFileSync __dirname + '/../resource/service-plugin.js', encoding: 'utf8'


class Service
  name: 'web-service'

  deployed: 0
  pending:  []

  deployFilter: (msg) =>
    if msg.stat?.done and msg.task in ['deployer', 'filesDeployer'] and msg.repo isnt 'test'
      @deployed += 1
      if @deployed > 2
        messenger.note 'deployments ready'
        while @pending.length
          @pending.shift()()

  constructor: ->
    for repo_name in ['css', 'html', 'js']
      unless config[repo_name]
        @deployed += 1

#     app.use (req, res, next) -> # log
#       messenger.note req.method + ' ' + req.url +
#                      if req.body? then ' ' + JSON.stringify(req.body) else ''
#       next()

    app.use (req, res, next) =>
      return next() if @deployed > 2
      @pending.push next

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
              res.send patch + '\n\n' + data
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
              messenger.note '[proxy response] ' + (pres?.statusCode or '?') +
                             ' ' + req.method + ' ' + url
              try
                res.json pres?.statusCode or 500, data or error: 'Server Error'
              catch
                try res.json 500, error: 'Server Error'

            client = restify.createJsonClient {url}
            messenger.note '[proxy request] ' + req.method + ' ' + url

            method = req.method.toLowerCase().replace 'delete', 'del'
            switch req.method
              when 'POST', 'PUT'
                client[method] url, req.body, handler
              else
                client[method] url, handler

    server = app.listen config.service.port, config.service.interface, =>
      bayeux = new faye.NodeAdapter {mount: '/bayeux', timeout: 45}
      bayeux.attach server

      bayeux.on 'subscribe', (client_id, channel) =>
        messenger.note '[client subscription] ' + client_id + ': ' + channel
        if channel is '/init'
          @publish '/init', {data: stats.data, ids: stats.ids}

      messenger.note 'listening @ ' + config.service.interface + ':' +
                     config.service.port

  incoming: (msg) =>
    if msg.type is 'stat-init'
      msgs = stats.init msg.data, msg.ids
    else
      msgs = stats.incoming msg
    for msg in msgs
      @publish '/update', msg
      @deployFilter msg

  publish: (channel, message) =>
#     messenger.note '[bayeux] ' + channel + ' : ' + JSON.stringify message
    bayeux.getClient().publish channel, message


module.exports = new Service

process.on 'message', module.exports.incoming

messenger module.exports
