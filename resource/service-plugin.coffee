
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
  id = stats?.ids?[repo]?[task]
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
  while cue.length and (ids = stats?.ids?[repo])?[task]? and cue[0].id is ids[task] + 1
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


class HUD
  div     = null
  repos   = {}
  pending = false
  ready   = false

  constructor: ->
    sticky = =>
      reattach div
      show()
      setTimeout sticky, 33

    loaded = =>
      ready = true
      @render() if pending
      pending = false
      sticky()

    document.addEventListener 'DOMContentLoaded', loaded, false
    window.addEventListener 'load', loaded, false

  render: =>
    unless ready
      return pending = true

    unless reattach div
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
          maxWidth:      '40%'
          opacity:       .85
          paddingRight:  '2px'
          verticalAlign: 'bottom'

        pt.title = create pt.div,
          background:   'linear-gradient(#374, #394, #374)'
          border:       '#122 solid 1px'
          borderBottom: 'transparent 0 solid'
          borderRadius: '17px 3px 17px 3px'
          color:        '#f8f8f8'
          display:      'inline-block'
          fontSize:     '11px'
          fontWeight:   'bold'
          height:       '20px'
          left:         '-2px'
          lineHeight:   '18px'
          marginRight:  '2px'
          padding:      '0 9px'
          textAlign:    'center'
          top:          '-1px'
        pt.title.innerHTML = repo.toUpperCase()

        pt.head = create pt.div,
          display:    'inline-block'
          lineHeight: '18px'

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
          node = create panel,
            background: '#455'
            fontWeight: 'bold'
            padding:    '2px'
            whiteSpace: 'normal'
          node.innerHTML = msg.title
        if msg.description
          node = create panel,
            padding:    '4px 2px'
            whiteSpace: 'normal'
          node.innerHTML = msg.description
        if msg.file
          node = create panel,
            background:   '#344'
            borderRadius: '3px'
            color:        '#ddd'
            fontWeight:   'bold'
            padding:      '3px'
          if msg.lines
            style node,
              border:       'solid 1px #455'
              borderBottom: 'solid 1px #233'
              borderRadius: '3px 3px 0 0'
          node.innerHTML = msg.file
          if msg.line and not msg.lines
            if typeof msg.line is 'object'
              node.innerHTML += ' @ lines ' + msg.line.join '-'
            else
              node.innerHTML += ' @ line ' + msg.line
        if msg.lines
          lines = create panel,
            background: '#455'
            color:      '#eee'
            left:       0
            margin:     '2px 0 0 0'
            position:   'absolute'
          for n in [msg.lines.from .. msg.lines.to]
            if msg.lines[n]?
              line = create lines,
                color:       '#eee'
                fontFamily:  '"Lucida Console", Monaco, monospace'
                padding:     '0 4px 0 2px'
                textAlign:   'right'
                whiteSpace:  'pre'
              if n is msg.line or (typeof msg.line is 'object' and n in msg.line)
                style line, background: '#633'
              line.innerHTML = n
          line_chars = 0
          for n in [msg.lines.from .. msg.lines.to]
            if msg.lines[n]?
              line_chars = Math.max line_chars, String(n).length
          push = line_chars * 10 + 10
          node = create panel,
            background: '#455'
            padding:    '2px 2px 2px ' + push + 'px'
            overflow:   'auto'
            zIndex:     2147483646
          for n in [msg.lines.from .. msg.lines.to]
            if (code = msg.lines[n])?
              line = create node,
                color:       '#eee'
                fontFamily:  '"Lucida Console", Monaco, monospace'
                overflow:    'visible'
                whiteSpace:  'pre'
              if n is msg.line or (typeof msg.line is 'object' and n in msg.line)
                style line, {fontWeight: 'bold', color: '#e66'}
              code = code.split('\t').join '    '
              cut = 0
              for i in [code.length - 1 .. 0]
                if code[i] is ' '
                  cut += 1
                else
                  break
              if cut
                spc = '<span style="background: #766;">' + code.substr(code.length - cut) + '</span>'
                code = code.substr(0, code.length - cut) + spc
              line.innerHTML = code or ' '

      issue_cue = []
      for task of symbols
        if (stat = tasks[task])?.count
          unless pt[task]
            pt[task] = create pt.head,
              display:    'inline-block'
              fontWeight: 'bold'
              fontSize:   '11px'
              lineHeight: '18px'
              margin:     '0 4px'

          out = symbols[task]

          status = 'load'
          status = 'done' if stat.done

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

      issue_cue.reverse()
      issue_cue.sort (a, b) ->
        return 1 if a.level is 'warn'
        -1

#       for issue, i in issue_cue when i < 3
#         add_info issue.info, issue.level
      if issue = issue_cue[0]
        add_info issue.info, issue.level
        style pt.div, opacity: 1

      style pt.title, background: 'linear-gradient(' + colors[repo_status].join(', ') + ')'

bayeux     = new Faye.Client '/bayeux', retry: .5
reload_i   = 0
hud        = new HUD
init       = true
msg_div    = null
msgs       = []
reconnect  = false
reloading  = false
service_up = false
show_id    = 0
stats      = new Stats


reattach = (node, parent=document.body) ->
  if node and node.parentNode isnt parent
    parent.appendChild node
  node

show = ->
  unless msgs.length
    if msg_div
      remove msg_div
      msg_div = null
    return

  unless reattach msg_div
    msg_div = create document.body,
      position: 'fixed'
      right:    '5px'
      bottom:   '5px'
      overflow: 'hidden'
      maxWidth: '20%'
      zIndex:   2147483647
  return

add = (msg) ->
  if typeof msg is 'string'
    msg = {repo: 'srv', note: msg}
  show_id += 1
  return if msgs.length > 20
  msgs.push msg
  show()

  div = create msg_div,
    background:   'linear-gradient(#122, #233, #122)'
    borderBottom: '#000 solid 1px'
    borderRadius: '10px'
    margin:       '3px 0 0'
    opacity:      .85
    overflow:     'hidden'
    paddingRight: '9px'
    zoom:         .01

  status = 'note'
  status = 'error' if msg.repo is 'error'
  status = 'warn'  if msg.repo is 'log'

  title = create div,
    background:   'linear-gradient(' + colors[status].join(', ') + ')'
    border:       '#122 solid 1px'
    borderRadius: '10px'
    color:        '#f8f8f8'
    display:      'inline-block'
    fontWeight:   'bold'
    fontSize:     '11px'
    height:       '18px'
    lineHeight:   '18px'
    padding:      '0 9px'
    textAlign:    'center'
  title.innerHTML = msg.repo.toUpperCase()

  content = create div,
    color:      '#eee'
    display:    'inline-block'
    fontSize:   '11px'
    lineHeight: '18px'
    padding:    '8px'
    whiteSpace: 'normal'
  content.innerHTML = msg.note

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


stringify = (obj) ->
  if obj and typeof obj is 'object' and JSON?.stringify
    return JSON.stringify obj
  String obj

if orig_log = console?.log
  console._log = console.log
  console.log = (args...) ->
    add {repo: 'log', note: (stringify(item) for item in args).join ' '}
    console._log args...

if orig_error = console?.error
  console._error = console.error
  console.error = (args...) ->
    add {repo: 'error', note: (stringify(item) for item in args).join ' '}
    console._error args...


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
        reload()
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

create = (parent, styles, tag='DIV') ->
  try
    parent.appendChild node = document.createElement tag.toUpperCase()
    style node,
      border:        '0 solid transparent'
      borderRadius:  0
      color:         '#eee'
      font:          '13px normal Arial,sans-serif'
      lineHeight:    '13px'
      margin:        0
      opacity:       1
      overflow:      'hidden'
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
  note:  ['#347', '#349', '#347']


reload_css = ->
  reload_i += 1
  for node in document.getElementsByTagName 'link'
    if src = node?.getAttribute('href')
      node.href = src + (if src.indexOf('?') > -1 then '&' else '?') +
                  '___uis_refresh=' + reload_i

  add {repo: 'css', note: 'refreshed styles'}

process_msg = (msg) ->
  switch msg?.type
    when 'note'
      add msg
    when 'stat'
      if msg.stat.done and msg.task in ['deployer', 'filesDeployer']
        if msg.repo is 'css'
          reload_css()
        else
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
    hud.render()
