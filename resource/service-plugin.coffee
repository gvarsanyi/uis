
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
msgs       = []
reconnect  = false
reloading  = false
service_up = false
show_id    = 0
stats      = new Stats

show = ->
  unless msgs.length
    if msg_div
      remove msg_div
      msg_div = null
    return

  unless msg_div
    msg_div = create document.body,
      position: 'fixed'
      right:    '5px'
      bottom:   '5px'
      overflow: 'hidden'
      maxWidth: '19%'
      zIndex:   2147483647
  return

add = (msg) ->
  if typeof msg is 'string'
    msg = {repo: 'srv', note: msg}
  show_id += 1
  msgs.push msg
  show()

  div = create msg_div,
    background:   'linear-gradient(#122, #233, #122)'
    borderBottom: '#000 solid 1px'
    borderRadius: '10px'
    lineHeight:   '18px'
    color:        '#eee'
    margin:       '3px 0 0'
    opacity:      .85
    overflow:     'hidden'
    paddingRight: '9px'
    whiteSpace:   'normal'
    zoom:         .01

  title = create div,
    background:   'linear-gradient(#347, #349, #347)'
    border:       '#122 solid 1px'
    borderRadius: '10px'
    color:        '#f8f8f8'
    display:      'inline-block'
    fontWeight:   'bold'
    height:       '18px'
    lineHeight:   '18px'
    marginRight:  '6px'
    padding:      '0 9px'
    textAlign:    'center'
  title.innerHTML = msg.repo.toUpperCase()
  div.appendChild document.createTextNode msg.note

  for i in [1 .. 10]
    do (i) ->
      setTimeout ->
        div.style.zoom = i / 10
      , i * 10
  for i in [84 .. 0] when i % 2 is 0
    do (i) ->
      setTimeout ->
        div.style.opacity = i / 100
        div.style.left = ((85 - i) / 85 * 255) + 'px'
      , 4825 + (85 - i) * 3
  setTimeout ->
    remove div
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

  div = create document.body,
    background: '#122'
    bottom:     0
    color:      '#fff'
    left:       0
    position:   'fixed'
    fontSize:   '32px'
    fontWeight: 'bold'
    opacity:    .85
    overflow:   'hidden'
    right:      0
    textAlign:  'center'
    top:        0
    zIndex:     2147483647
  div.innerHTML = 'reconnecting...'
  location.reload true

create = (parent, styles, tag='DIV') ->
  try
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

remove = (node) ->
  try node.parentNode.removeChild node

style = (node, styles) ->
  try node.style[k] = v for k, v of styles

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
          borderBottom:  'solid 0px transparent'
          borderRadius:  '17px 3px 3px 3px'
          bottom:        0
          display:       'inline-block'
          margin:        '0 1%'
          paddingRight:  '2px'
          maxWidth:      '25%'
          verticalAlign: 'bottom'

        pt.title = create pt.div,
          background:   'linear-gradient(#374, #394, #374)'
          border:       '#122 solid 1px'
          borderBottom: 'transparent 0 solid'
          borderRadius: '17px 3px 17px 3px'
          color:        '#f8f8f8'
          display:      'inline-block'
          fontWeight:   'bold'
          height:       '20px'
          left:         '-2px'
          lineHeight:   '18px'
          marginRight:   '2px'
          padding:      '0 9px'
          textAlign:    'center'
          top:          '-1px'
        pt.title.innerHTML = repo.toUpperCase()

        pt.head = create pt.div,
          display:    'inline-block'
          lineHeight: '18px'
          fontSize:   '11px'

        pt.info = create pt.div
        pt.error = create pt.info
        pt.warn  = create pt.info

      for task, stat of tasks when symbols[task] and stat.count
        unless pt[task]
          for t of symbols when pt[t]
            remove pt[t]
            delete pt[t]
          break

      repo_status = 'done'
      pt.error.innerHTML = ''
      pt.warn.innerHTML = ''
      touched = {}
      shown_issues = 0
      hidden_issues = 0

      add_info = (msg, status='warn') ->
        if shown_issues > 2
          hidden_issues += 1
          return
        shown_issues += 1
        if touched[status]
          create pt[status], null, 'br'
        touched[status] = true
        panel = create pt[status],
          background:   '#233'
          borderLeft:   colors[status][0] + ' groove 2px'
          borderRadius: '3px'
          display:      'inline-block'
          margin:       '3px'
          padding:      '3px'
          width:        '100%'
        if msg.title
          div = create panel,
            background: '#455'
            fontWeight: 'bold'
            padding:    '2px'
            whiteSpace: 'normal'
          div.innerHTML = msg.title
        if msg.description
          div = create panel,
            padding:    '4px 2px'
            whiteSpace: 'normal'
          div.innerHTML = msg.description
        if msg.file
          div = create panel,
            color:      '#ddd'
            fontWeight: 'bold'
            textAlign:  'right'
            padding:    '2px'
          div.innerHTML = msg.file
          if msg.line
            if typeof msg.line is 'object'
              div.innerHTML += ' : ' + msg.line.join '-'
            else
              div.innerHTML += ' : ' + msg.line
        if msg.lines
          div = create panel,
            background: '#455'
            padding:    '2px'
          for n in [msg.lines.from .. msg.lines.to]
            if msg.lines[n]?
              line = create div,
                color:      '#eee'
                fontFamily: '"Lucida Console", Monaco, monospace'
                whiteSpace: 'pre'
              out = ''
              if String(n).length < String(msg.lines.to).length
                out += ' '
              if n is msg.line or (typeof msg.line is 'object' and n in msg.line)
                style line, {fontWeight: 'bold', background: '#633'}
              line.innerHTML = out + n + ' ' + msg.lines[n]

      issue_cue = []
      for task of symbols
        if (stat = tasks[task])?.count
          unless pt[task]
            pt[task] = create pt.head,
              display:    'inline-block'
              fontSize:   '9px'
              fontWeight: 'bold'
              lineHeight: '18px'
              margin:     '0 4px'

          out = symbols[task]

          status = 'load'
          status = 'done'  if stat.done

          if n = stat.error?.length
            status = 'error'
            out += ':' + n
            for info in stat.error
              issue_cue.push {level: 'error', info}
            if n = stat.warning?.length
              out += '<span style="color: ' + colors['warn'][0] + ';">+' + n + '</span>'
              for info in stat.warning
                issue_cue.push {level: 'warn', info}
          else if n = stat.warning?.length
            status = 'warn'
            out += ':' + n
            for info in stat.warning
              issue_cue.push {level: 'warn', info}
          style pt[task], color: colors[status][0]

          pt[task].innerHTML = out

          repo_status = 'check' if repo_status is 'done'
          unless stat.done or repo_status in ['warn', 'error']
            repo_status = 'load'
          if stat.warning?.length and repo_status isnt 'error'
            repo_status = 'warn'
          if stat.error?.length
            repo_status = 'error'

      issue_cue.sort (a, b) ->
        return 1 if a.level is 'warn'
        -1

      for issue, i in issue_cue when i < 3
        add_info issue.info, issue.level

      style pt.title, background: 'linear-gradient(' + colors[repo_status].join(', ') + ')'

hud = new HUD

symbols =
  filesLoader:      'load'
  filesCompiler:    'compile'
  concatenator:     'concat'
  filesMinifier:    'minify'
  minifier:         'minify'
  filesDeployer:    'deploy'
  deployer:         'deploy'
  filesLinter:      'lint'
  tester:           'test'
  coverageReporter: 'cover'

colors =
  load:  ['#001', '#114', '#001']
  done:  ['#eee', '#fff', '#eee']
  check: ['#394', '#6c7', '#394']
  warn:  ['#e81', '#fb4', '#e81']
  error: ['#e33', '#f66', '#e33']

process_msg = (msg) ->
  switch msg?.type
    when 'note'
      add msg
    when 'stat'
      if msg.stat.done and msg.task in ['deployer', 'filesDeployer']
        reload()
      hud.render()

subscription = bayeux.subscribe '/update', (msg) ->
  for msg in stats.incoming msg
    process_msg msg

subscription.then ->
  stats_subscription = bayeux.subscribe '/init', (msg) ->
    stats_subscription.cancel()
    for msg in stats.init msg.data, msg.ids
      process_msg msg
