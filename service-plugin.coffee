
bayeux  = new Faye.Client '/bayeux', retry: .5
init    = true
msg_div = null
msg_id  = '___uis-msg'
msgs    = []
show_id = 0
stats   = {}

show = ->
  msg_div = document.getElementById msg_id

  unless msgs.length
    if msg_div
      msg_div.parentNode.removeChild msg_div
    return

  unless msg_div
    msg_div = document.createElement 'DIV'
    msg_div.id = msg_id
    msg_div.style[k] = v for k, v of {
      position: 'fixed'
      right:    0
      bottom:   '5px'
      overflow: 'hidden'
      width:    '255px'
      widthMax: '10%'
      zIndex:   2147483647
    }
    document.body.appendChild msg_div
  return

add = (msg) ->
  show_id += 1
  msgs.push msg
  show()

  div = document.createElement 'DIV'
  div.style[k] = v for k, v of {
    background:   '#20404d'
    borderLeft:   '3px solid #011'
    borderRight:  '3px solid #011'
    borderRadius: '3px'
    color:        '#f8f8f8'
    fontSize:     '16px'
    fontWeight:   'bold'
    margin:       '0 0 3px'
    opacity:      .85
    overflow:     'hidden'
    padding:      '4px'
    whiteSpace:   'normal'
    width:        '98%'
    zoom:         .01
  }

  div.innerHTML = msg

  msg_div.appendChild div
  for i in [1 .. 10]
    do (i) ->
      setTimeout ->
        div.style.zoom = i / 10
      , i * 10
  for i in [84 .. 0] when i % 2 is 0
    do (i) ->
      setTimeout ->
        div.style.opacity = i / 100
        div.style.marginLeft = ((85 - i) / 85 * 255) + 'px'
      , 4825 + (85 - i) * 3
  setTimeout ->
    msg_div.removeChild div
    msgs.shift()
    show()
  , 5000

bayeux.on 'transport:down', ->
  add 'disconnected from service'

bayeux.on 'transport:up', ->
  unless init
    add 'service is back!'
    reload()
  init = false

reload = ->
  add 'refreshing ...'
  location.reload true

subscription = bayeux.subscribe '/update', (msg) ->
  console.log 'msg:', msg
  switch msg?.type
    when 'note'
      add '[' + msg.repo + '] ' + msg.note
    when 'stat'
      stats[msg.repo] ?= {}
      stats[msg.repo][msg.task] = msg.stat
      if msg.stat.done
        add '[' + msg.repo + '] ' + msg.task + ' done'
        if msg.task in ['deployer', 'filesDeployer']
          reload()

subscription.then ->
  stats_subscription = bayeux.subscribe '/stat', (msg) ->
    stats = msg
    stats_subscription.cancel()
