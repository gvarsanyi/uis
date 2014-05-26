fs         = require 'fs'
path       = require 'path'

bodyparser = require 'body-parser'
express    = require 'express'
faye       = require 'faye'
restify    = require 'restify'

config     = require './config'
messenger  = require './messenger'
stats      = require './stats'


app    = express()
bayeux = null
server = null


process.on 'uncaughtException', (err) ->
  switch err.code
    when 'EADDRINUSE'
      console.error 'port ' + config.service.port + ' is already in use'
    when 'EACCES'
      msg = config.service.port
      unless process.getuid() is 0 or config.service.port > 1023
        msg += ' (you need root permissions)'
      console.error 'No permission to open port', msg
    else
      console.error err
  process.exit 1


class Service
  name: 'web-service'

  deployed: {}
  pending:  {css: [], html: [], js: []}

  constructor: ->
    @preloadPatch()

    for repo_name in ['css', 'html', 'js']
      unless config[repo_name]
        @deployed[repo_name] = true

    app.use bodyparser()

#     app.use (req, res, next) -> # log
#       console.log req.method + ' ' + req.url +
#                   if req.body? then ' ' + JSON.stringify(req.body) else ''
#       next()

    app.use (req, res, next) =>
      switch req.url
        when @cssDeployUrl
          if @jsDeployUrl and not @deployed.js
            return @pending.css.push next
        when @jsDeployUrl
          unless @deployed.js or (not @patch and config.service.hud)
            return @pending.js.push next
        else
          if req.url.split('/').pop().split('.').pop() in ['html', '']
            unless @deployed.html
              return @pending.html.push next

      next()

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

    contents = path.resolve config.service.contentsDir

    if config.css?.deploy
      css_resolved = path.resolve config.css.deploy
      if css_resolved.substr(0, contents.length) is contents
        @cssDeployUrl = css_resolved.substr contents.length

    if config.js?.deploy
      js_resolved = path.resolve config.js.deploy
      if js_resolved.substr(0, contents.length) is contents
        @jsDeployUrl = js_resolved.substr contents.length

    if config.service.hud and @jsDeployUrl
      app.get @jsDeployUrl, (req, res) =>
        fs.readFile js_resolved, encoding: 'utf8', (err, data) =>
          if err
            res.type 'json'
            res.json 500, error: 'Server Error: loading ' + js_resolved
          else
            res.send @patch + data

    app.use express.static contents

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
              if config.service.log
                console.log '[proxy response] ' + (pres?.statusCode or '?') +
                            ' ' + req.method + ' ' + url
              try
                res.json pres?.statusCode or 500, data or error: 'Server Error'
              catch
                try res.json 500, error: 'Server Error'

            client = restify.createJsonClient {url}
            if config.service.log
              console.log '[proxy request] ' + req.method + ' ' + url

            method = req.method.toLowerCase().replace 'delete', 'del'
            switch req.method
              when 'POST', 'PUT'
                console.log 'req.body pre', req
                client[method] url, req.body, handler
              else
                client[method] url, handler

    server = app.listen config.service.port, config.service.interface, =>
      bayeux = new faye.NodeAdapter {mount: '/bayeux', timeout: 45}
      bayeux.attach server

      bayeux.on 'subscribe', (client_id, channel) =>
        if config.service.log
          console.log '[client subscription] ' + client_id + ': ' + channel
        if channel is '/init'
          @publish '/init', {data: stats.data, ids: stats.ids}

      if config.service.log
        console.log 'listening @ ' + config.service.interface + ':' +
                    config.service.port

  deployCheck: (repo) =>
    if @deployed[repo] and (@patch or not config.service.hud or repo isnt 'js')
      while @pending[repo].length
        @pending[repo].shift()()

  deployFilter: (msg) =>
    return if @_deployed

    deploy_repo = msg.repo in ['css', 'html', 'js']
    deploy_task = msg.task in ['deployer', 'filesDeployer']
    if deploy_repo and ((msg.stat?.done and deploy_task) or msg.stat?.error?.length)
      @deployed[msg.repo] = true
      @deployCheck msg.repo

  incoming: (msg) =>
    if msg.type is 'stat-init'
      msgs = stats.init msg.data, msg.ids
    else
      msgs = stats.incoming msg
    for msg in msgs
      @publish '/update', msg
      @deployFilter msg

  preloadPatch: =>
    if config.service.hud
      faye_path = __dirname + '/../node_modules/faye/browser/faye-browser.js'
      fs.readFile faye_path, encoding: 'utf8', (err, src1) =>
        throw new Error(err) if err
        src1 = src1.replace '//@ sourceMappingURL=faye-browser-min.js.map', ''

        plugin_path = __dirname + '/../resource/service-plugin.js'
        fs.readFile plugin_path, encoding: 'utf8', (err, src2) =>
          throw new Error(err) if err
          @patch = src1 + '\n' + src2 + '\n\n'
        @deployCheck 'js'

  publish: (channel, message) =>
#     console.log '[bayeux] ' + channel + ' : ' + JSON.stringify message
    bayeux.getClient().publish channel, message


module.exports = new Service

process.on 'message', module.exports.incoming

messenger module.exports
