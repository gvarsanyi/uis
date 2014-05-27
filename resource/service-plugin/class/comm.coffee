
class Comm
  cssReloadCount: 0
  init:           true
  reconnect:      false
  reloading:      false
  serviceUp:      false

  constructor: ->
    @bayeux = new Faye.Client '/bayeux', retry: .5
    @bayeux.on 'transport:down', =>
      setTimeout =>
        unless @serviceUp
          hud.add 'disconnected'
          @reconnect = true
      , 1

    @bayeux.on 'transport:up', =>
      unless @init
        setTimeout =>
          if @reconnect
            @reload()
        , 1
      @init      = false
      @serviceUp = true

    subscription = @bayeux.subscribe '/update', (msg) =>
      for msg in stats.incoming msg
        @processMsg msg

    subscription.then =>
      stats_subscription = @bayeux.subscribe '/init', (msg) =>
        stats_subscription.cancel()
        for msg in stats.init msg.data, msg.ids
          @processMsg msg
        hud.render()

    @takeOverConsole()

  reload: (msg='reloading') ->
    return if @reloading
    @reloading = true

    div = DOM.create document.body,
      background: '#122'
      bottom:     0
      color:      '#fff'
      left:       0
      position:   'fixed'
      fontSize:   '32px'
      lineHieght: '32px'
      fontWeight: 'bold'
      opacity:    .85
      overflow:   'hidden'
      padding:    '10% 0 0 0'
      right:      0
      textAlign:  'center'
      top:        0
      zIndex:     2147483647
    div.innerHTML = msg + '...'
    location.reload true

  reloadCss: ->
    @cssReloadCount += 1
    for node in document.getElementsByTagName 'link'
      if src = node?.getAttribute('href')
        node.href = src + (if src.indexOf('?') > -1 then '&' else '?') +
                    '___uis_refresh=' + @cssReloadCount

    hud.add {repo: 'css', note: 'refreshed styles'}

  processMsg: (msg) =>
    switch msg?.type
      when 'note'
        hud.add msg
      when 'stat'
        if msg.stat.done and msg.task in ['deployer', 'filesDeployer']
          if msg.repo is 'css'
            @reloadCss()
          else if msg.repo in ['html', 'js']
            @reload()
        hud.render()

  takeOverConsole: ->
    stringify = (obj) ->
      if obj and typeof obj is 'object' and JSON?.stringify
        return JSON.stringify obj
      String obj

    if console?.log
      console._log = console.log
      console.log = (args...) ->
        hud.add {repo: 'log', note: (stringify(item) for item in args).join ' '}
        console._log args...

    if console?.error
      console._error = console.error
      console.error = (args...) ->
        hud.add {repo: 'error', note: (stringify(item) for item in args).join ' '}
        console._error args...
