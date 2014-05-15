
message_cue = {}

cue_processor = (msg) ->
  unless typeof msg.id is 'number' and msg.id >= 0
    throw new Error 'invalid/missing msg id: ' + msg

  repo = msg.repo
  task = msg.task
  if msg.type is 'note'
    repo = task = 'note'

  unless repo and task
    throw new Error 'invalid/missing msg.repo and/or msg.task: ' + msg

  message_cue[repo] ?= {}
  message_cue[repo][task] ?= []
  id = stats?.ids[repo]?[task]
  return reload('server restarting') if id? and id >= msg.id
  if stats?.data and (not id? or msg.id is id + 1)
    stats.ids[repo] ?= {}
    stats.ids[repo][task] = msg.id
    return [msg]

  (cue = message_cue[repo][task]).push msg
  cue.sort (a, b) ->
    a.id - b.id

  ready_list repo, task

ready_list = (repo, task) ->
  list = []
  cue = message_cue[repo]?[task] or []
  while cue.length and (ids = stats?.ids[repo])?[task]? and cue[0].id is ids[task] + 1
    ids[task] += 1
    list.push cue.shift()
  list


class Stats
  data: null
  ids: null

  init: (initial_stats, initial_ids) =>
    unless not @data? and initial_stats? and typeof initial_stats is 'object' and
    initial_ids? and typeof initial_ids is 'object'
      throw new Error 'init-stat: ' + arguments
    @data = initial_stats
    @ids  = initial_ids

    list = []
    for repo, repo_data of initial_stats
      for task of repo_data
        for msg in ready_list repo, task
          list.push msg
    list

  incoming: (msg) =>
    msgs = cue_processor msg
    for msg in msgs when msg.type is 'stat'
      if not (id = @ids?[msg.repo]?[msg.task])? or id <= msg.id
        @data[msg.repo] ?= {}
        @data[msg.repo][msg.task] = msg.stat
        @ids[msg.repo] ?= {}
        @ids[msg.repo][msg.task] = msg.id
    msgs

bayeux     = new Faye.Client '/bayeux', retry: .5
init       = true
msg_div    = null
msg_id     = '___uis-msg'
msgs       = []
reconnect  = false
reloading  = false
service_up = false
show_id    = 0
stats      = new Stats

show = ->
  unless msgs.length
    if msg_div
      msg_div.parentNode.removeChild msg_div
    return

  unless msg_div
    msg_div = document.createElement 'DIV'
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
  service_up = false
  setTimeout ->
    unless service_up
      add 'disconnected'
      reconnect = true
  , 1

bayeux.on 'transport:up', ->
  unless init
    setTimeout ->
      if reconnect
        reload 'reconnecting'
    , 1
  init       = false
  service_up = true

reload = (msg='reloading') ->
  return if reloading
  reloading = true

  div = document.createElement 'DIV'
  div.style[k] = v for k, v of {
    background: '#122'
    bottom:     0
    color:      '#fff'
    left:       0
    position:   'fixed'
    fontSize:   '32px'
    fontWeight: '32px'
    opacity:    .85
    overflow:   'hidden'
    right:      0
    textAlign:  'center'
    top:        0
    zIndex:     2147483647
  }
  div.innerHTML = msg + '...'
  document.body.appendChild div
  location.reload true

create = (parent, styles, tag='DIV') ->
  parent.appendChild node = document.createElement tag.toUpperCase()
  style node,
    border:        '0 solid transparent'
    borderRadius:  0
    color:         '#eee'
    font:          '11px normal Arial,sans-serif'
    lineHeight:    '11px'
    margin:        0
    opacity:       1
    padding:       0
    position:      'relative'
    verticalAlign: 'top'
    whiteSpace:    'nowrap'
    zIndex:        2147483647
  if styles
    style node, styles
  node

style = (node, styles) ->
  node.style[k] = v for k, v of styles

class HUD
  div   = null
  repos = {}

  render: =>
    unless div
      div = create document.body,
        position: 'fixed'
        left:     0
        bottom:   0
        width:    '80%'

    for repo, tasks of stats.data
      unless pt = repos[repo]
        pt = repos[repo] = {}
        pt.div = create div,
          background:    'linear-gradient(#122, #233, #122)'
          border:        '#011 solid 1px'
          borderRadius:  '9px 9px 0 0'
          bottom:        0
          display:       'inline-block'
          height:        '18px'
          lineHeight:    '18px'
          margin:        '0 8px'
          opacity:       .5
          paddingRight:  '6px'

        pt.title = create pt.div,
          background:   'linear-gradient(#374, #394, #374)'
          border:       '#122 solid 1px'
          borderRadius: '9px 0 0 0'
          color:        '#f8f8f8'
          display:      'inline-block'
          fontWeight:   'bold'
          height:       '18px'
          left:         '-2px'
          lineHeight:   '18px'
          marginRight:   '4px'
          padding:      '0 5px 0 7px'
          textAlign:    'center'
          top:          '-1px'
        pt.title.innerHTML = repo.toUpperCase()

        pt.head = create pt.div,
          display:    'inline-block'
          lineHeight: '18px'
          fontSize:   '11px'

      pt.head.innerHTML = '12 files, 323,234 bytes'

hud = new HUD

process_msg = (msg) ->
  switch msg?.type
    when 'note'
      add '[' + msg.repo + '] ' + msg.note
    when 'stat'
      if msg.stat.done
        if msg.task in ['deployer', 'filesDeployer']
          reload()
        else
          add '[' + msg.repo + '] ' + msg.task + ' done'

subscription = bayeux.subscribe '/update', (msg) ->
  for msg in stats.incoming msg
    process_msg msg
  hud.render()

subscription.then ->
  stats_subscription = bayeux.subscribe '/init', (msg) ->
    stats_subscription.cancel()
    for msg in stats.init msg.data, msg.ids
      process_msg msg
    hud.render()
