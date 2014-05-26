
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

  repos: (name) =>
    return [name] if name
    (k for k of @data)

  hasError: (repo) =>
    for repo in @repos repo
      for task, inf of @data[repo] when not inf.muted
        return inf.error[0] if inf.error?.length
    false

  hasWarning: (repo) =>
    for repo in @repos repo
      for task, inf of @data[repo] when not inf.muted
        return inf.warning[0] if inf.warning?.length
    false

  isDone: (repo) =>
    for repo in @repos repo
      for task, inf of @data[repo]
        continue if inf.error?.length
        return false unless inf.done
    true

  state: (repo) =>
    state = 'load'
    if @hasError repo
      state = 'error'
    else if @hasWarning repo
      state = 'warn'
    else if @isDone repo
      state = 'check'
    state

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
  pending = false
  ready   = false

  constructor: ->
    loaded = =>
      ready = true
      @render() if pending
      pending = false

    document.addEventListener 'DOMContentLoaded', loaded, false
    window.addEventListener 'load', loaded, false

  render: =>
    unless ready
      return pending = true

    unless @div
      @panel = create document.body,
        bottom:        '5px'
        position:      'fixed'
        right:         '5px'
        verticalAlign: 'bottom'
        maxWidth:      '20%'

      @msgs = create @panel

      @info = create @panel

      @div = create document.body,
        background:    'linear-gradient(#122, #233, #122)'
        border:        '#011 solid 1px'
        borderBottom:  'solid 0px transparent'
        borderRight:   'solid 0px transparent'
        borderRadius:  '32px 0 0 0'
        bottom:        0
        height:        '24px'
        position:      'fixed'
        right:         0
        verticalAlign: 'bottom'
        width:         '24px'

      @state = create @div,
        color:        '#0a1616'
        fontSize:     '18px'
        height:       '18px'
        lineHeight:   '18px'
        position:     'absolute'
        right:        0
        top:          '4px'
        textAlign:    'center'
        textShadow:   '1px 1px #000'
        width:        '18px'
        '@-moz-keyframes':    'spin{100%{-moz-transform: rotate(360deg);}}'
        '@-webkit-keyframes': 'spin{100%{-webkit-transform: rotate(360deg);}}'
        '@keyframes':         'spin{100%{transform:rotate(360deg);}}'

    state = stats.state()
    @state.innerHTML = state_symbols[state]
    anim = if state is 'load' then 'spin 1s linear infinite' else 'none'
    style @state,
      '-webkit-animation': anim
      animation:           anim
      color:               colors[state][0]
    style @title, color: colors[state][0]

    status = 'error'
    unless msg = stats.hasError()
      msg = stats.hasWarning()
      status = 'warn'

    unless msg
      style @info, display: 'none'
    else
      @info.innerHTML = ''
      style @info,
        background:   '#233'
        borderLeft:   colors[status][0] + ' groove 2px'
        borderRadius: '3px'
        display:      'block'
        margin:       '3px'
        maxHeight:    '250px'
        overflowX:    'hidden'
        overflowY:    'auto'
        padding:      '3px'
        width:        '100%'
      if msg.title
        node = create @info,
          background: '#455'
          fontWeight: 'bold'
          padding:    '2px'
          whiteSpace: 'normal'
        node.innerHTML = msg.title
      if msg.description
        node = create @info,
          padding:    '4px 2px'
          whiteSpace: 'pre'
        node.innerHTML = msg.description
      if msg.file
        node = create @info,
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
      if msg.table
        table = create @info,
          background: '#233'
          display:    'table'
        , 'table'

        has_title = false
        for col in msg.table.columns
          col.align = 'left' if col.align isnt 'right'
          has_title = true if col.title?

        if has_title
          tr = create table, display: 'table-row', 'tr'
          for col in msg.table.columns
            th = create tr,
              background:    '#344'
              borderSpacing: '1px'
              color:         '#eee'
              display:       'table-cell'
              fontWeight:    'bold'
              padding:       '2px'
              textAlign:     col.align
            , 'th'
            th.innerHTML = col.title if col.title?

        for row, row_n in msg.table.data
          tr = create table, display: 'table-row', 'tr'
          for col, i in msg.table.columns
            td = create tr,
              background:    (if row_n % 2 then '#485a5a' else '#455')
              borderSpacing: '1px'
              color:         '#eee'
              display:       'table-cell'
              padding:       '2px'
              textAlign:     col.align
            , 'td'
            td.innerHTML = if col.src? then row[col.src] else row[i]
      if msg.lines
        lines = create @info,
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
        node = create @info,
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

      if table and (w1 = table.offsetWidth) > w2 = @info.offsetWidth - 28
        style table, zoom: w2 / w1

  showId:   0
  shownMsg: 0
  add: (msg) ->
    return if @shownMsg > 20
    @showId   += 1
    @shownMsg += 1

    if typeof msg is 'string'
      msg = {repo: 'srv', note: msg}

    div = create @msgs,
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

    setTimeout =>
      remove div
      @shownMsg -= 1
    , 5000


bayeux     = new Faye.Client '/bayeux', retry: .5
reload_i   = 0
hud        = new HUD
init       = true
reconnect  = false
reloading  = false
service_up = false
stats      = new Stats


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
      boxSizing:     'border-box'
      color:         '#eee'
      display:       'block'
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
      zoom:          1
    if styles
      style node, styles
  node

remove = (node) ->
  try node.parentNode.removeChild node

style = (node, styles) ->
  try node.style[k] = v for k, v of styles

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
  coverageReporter: 'coverage'

colors =
  load:  ['#18e', '#4bf', '#18e']
  done:  ['#eee', '#fff', '#eee']
  check: ['#394', '#6c7', '#394']
  warn:  ['#e81', '#fb4', '#e81']
  error: ['#e33', '#f66', '#e33']
  note:  ['#347', '#349', '#347']

state_symbols =
  load:  '&#8987;'
  check: '&#10003;'
  done:  '&#10003;'
  warn:  '&#9888;'
  error: '&#10007;'
  note:  '&#9432;'


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
      if msg.stat.done and msg.task in ['deployer', 'filesDeployer'] and msg.repo isnt 'test'
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
