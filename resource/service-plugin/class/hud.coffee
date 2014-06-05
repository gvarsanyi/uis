
class HUD
  pending = false
  ready   = false

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

  constructor: ->
    loaded = =>
      ready = true
      @render() if pending
      pending = false

    document.addEventListener 'DOMContentLoaded', loaded, false
    window.addEventListener 'load', loaded, false

    @infoHidden = 0
    if (pos = document.cookie?.indexOf?('uis_info_hidden=')) > -1
      @setInfoVisibility Number document.cookie.substr pos + 16, 1

  hideBin: {warn: 0, err: 1, log: 2}

  isHidden: (opt) =>
    !!((@infoHidden >> @hideBin[opt]) % 2)

  setHidden: (opt, to=true) =>
    unless !!to is @isHidden opt
      diff = Math.pow 2, @hideBin[opt]
      @setInfoVisibility @infoHidden + diff * if to then 1 else -1

      if opt is 'log'
        DOM.style @msgs, display: if to then 'none' else 'block'
      else
        DOM.style @info, display: if @shouldShowInfo() then 'block' else 'none'

  setInfoVisibility: (to) =>
    to = 0 unless 8 > to > 2 or to is 1 or to is 0
    @infoHidden = to
    year_off = new Date (new Date).getTime() + 365 * 24 * 60 * 60 * 1000
    document.cookie = 'uis_info_hidden=' + to + '; expires=' + year_off.toUTCString()

  shouldShowInfo: =>
    @hasMsg and (
     (@msgStatus is 'error' and not @isHidden 'err') or
     (@msgStatus is 'warn' and not @isHidden 'warn')
    )


  render: =>
    unless ready
      return pending = true

    unless @div
      @panel = DOM.create document.body,
        bottom:        '5px'
        position:      'fixed'
        right:         '5px'
        verticalAlign: 'bottom'
        maxWidth:      '20%'

      @msgs = DOM.create @panel

      @info = DOM.create @panel

      @div = DOM.create document.body,
        background:    'linear-gradient(#122, #233, #122)'
        border:        '#011 solid 1px'
        borderBottom:  'solid 0px transparent'
        borderRight:   'solid 0px transparent'
        borderRadius:  '32px 0 0 0'
        bottom:        '-40px'
        height:        '64px'
        position:      'fixed'
        right:         '-150px'
        verticalAlign: 'bottom'
        width:         '174px'
        '-webkit-touch-callout': 'none'
        '-webkit-user-select': 'none'
        '-khtml-user-select': 'none'
        '-moz-user-select': 'none'
        '-ms-user-select': 'none'
        'user-select': 'none'
        'cursor': 'pointer'
      @div.title = 'Toggle info visibility'
      @div.addEventListener 'click', =>
        if String(@div.style?.right).substr(0, 1) is '0'
          setTimeout =>
            DOM.style @div, {right: '-150px', bottom: '-40px'}
          , 10
        else
          DOM.style @div, {right: 0, bottom: 0}

      @state = DOM.create @div,
        color:        '#0a1616'
        fontSize:     '18px'
        height:       '18px'
        left:         '5px'
        lineHeight:   '18px'
        position:     'absolute'
        top:          '4px'
        textAlign:    'center'
        textShadow:   '1px 1px #000'
        width:        '18px'
        '@-moz-keyframes':    'spin{100%{-moz-transform: rotate(360deg);}}'
        '@-webkit-keyframes': 'spin{100%{-webkit-transform: rotate(360deg);}}'
        '@keyframes':         'spin{100%{transform:rotate(360deg);}}'

      @options = DOM.create @div, margin: '6px 0 0 29px'
      @toggles = {}
      inline = {display: 'inline', verticalAlign: 'bottom', lineHeight: '17px', cursor: 'pointer'}
      for toggle, title of {log: 'logs &amp; notifications', warn: 'warnings', err: 'errors'}
        do (toggle, title) =>
          chk   = DOM.create @options, inline, 'input:checkbox', id: '___uis_opt_' + toggle
          label = DOM.create @options, inline, 'label', for: '___uis_opt_' + toggle
          label.innerHTML = ' ' + title
          chk.checked = not @isHidden toggle
          chk.addEventListener 'change', =>
            @setHidden toggle, not chk.checked
#             DOM.style @div, {right: '-150px', bottom: '-40px'}
          br    = DOM.create @options, inline, 'br'
          @toggles[toggle] = {chk, label, br}

    state = stats.state()
    @state.innerHTML = state_symbols[state]
    anim = if state is 'load' then 'spin 1s linear infinite' else 'none'
    DOM.style @state,
      '-webkit-animation': anim
      animation:           anim
      color:               colors[state][0]
    DOM.style @title, color: colors[state][0]

    status = 'error'
    unless msg = stats.hasError()
      msg = stats.hasWarning()
      status = 'warn'

    @hasMsg = !!msg
    @msgStatus = status

    unless msg
      DOM.style @info, display: 'none'
    else
      @info.innerHTML = ''
      DOM.style @info,
        background:   '#233'
        borderLeft:   colors[status][0] + ' groove 2px'
        borderRadius: '3px'
        display:      if @shouldShowInfo() then 'block' else 'none'
        left:         0
        margin:       '3px'
        maxHeight:    '250px'
        overflowX:    'hidden'
        overflowY:    'auto'
        padding:      '3px'
        width:        '100%'
      if msg.title
        node = DOM.create @info,
          background: '#455'
          fontWeight: 'bold'
          padding:    '2px'
          whiteSpace: 'normal'
        node.innerHTML = msg.title
      if msg.description
        node = DOM.create @info,
          padding:    '4px 2px'
          whiteSpace: 'pre'
        node.innerHTML = msg.description
      if msg.file
        node = DOM.create @info,
          background:   '#344'
          borderRadius: '3px'
          color:        '#ddd'
          fontWeight:   'bold'
          padding:      '3px'
        if msg.lines
          DOM.style node,
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
        table = DOM.create @info,
          background:  '#233'
          display:     'table'
          tableLayout: 'fixed'
        , 'table'

        has_title = false
        for col in msg.table.columns
          col.align = 'left' if col.align isnt 'right'
          has_title = true if col.title?

        if has_title
          tr = DOM.create table, display: 'table-row', 'tr'
          for col in msg.table.columns
            th = DOM.create tr,
              background:    '#344'
              borderSpacing: '1px'
              color:         '#eee'
              display:       'table-cell'
              fontWeight:    'bold'
              padding:       '2px'
              textAlign:     col.align
              width:         col.width or 'auto'
            , 'th'
            th.innerHTML = col.title if col.title?

        for row, row_n in msg.table.data
          tr = DOM.create table, display: 'table-row', 'tr'
          for col, i in msg.table.columns
            td = DOM.create tr,
              background:    (if row_n % 2 then '#485a5a' else '#455')
              borderSpacing: '1px'
              color:         '#eee'
              display:       'table-cell'
              padding:       '2px'
              textAlign:     col.align
              width:         col.width or 'auto'
            , 'td'
            content = if col.src? then row[col.src] else row[i]
            switch col.highlight
              when 'basename'
                parts = content.split '/'
                file = parts.pop()
                dir = if parts.length then parts.join('/') + '/' else ''
                parts = file.split '.'
                file = parts.shift()
                ext = if parts.length then '.' + parts.join('.') else ''
                content = file
                if dir
                  content = '<span style="color: #999">' + dir + '</span>' + content
                if ext
                  content += '<span style="font-size: 9px; color: #999">' + ext + '</span>'
            td.innerHTML = content
      if msg.lines
        lines = DOM.create @info,
          background: '#455'
          color:      '#eee'
          left:       0
          margin:     '2px 0 0 0'
          position:   'absolute'
        for n in [msg.lines.from .. msg.lines.to]
          if msg.lines[n]?
            line = DOM.create lines,
              color:       '#eee'
              fontFamily:  '"Lucida Console", Monaco, monospace'
              padding:     '0 4px 0 2px'
              textAlign:   'right'
              whiteSpace:  'pre'
            if n is msg.line or (typeof msg.line is 'object' and n in msg.line)
              DOM.style line, background: '#633'
            line.innerHTML = n
        line_chars = 0
        for n in [msg.lines.from .. msg.lines.to]
          if msg.lines[n]?
            line_chars = Math.max line_chars, String(n).length
        push = line_chars * 10 + 10
        node = DOM.create @info,
          background: '#455'
          padding:    '2px 2px 2px ' + push + 'px'
          overflow:   'auto'
          zIndex:     2147483646
        for n in [msg.lines.from .. msg.lines.to]
          if (code = msg.lines[n])?
            line = DOM.create node,
              color:       '#eee'
              fontFamily:  '"Lucida Console", Monaco, monospace'
              overflow:    'visible'
              whiteSpace:  'pre'
            if n is msg.line or (typeof msg.line is 'object' and n in msg.line)
              DOM.style line, {fontWeight: 'bold', color: '#e66'}
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
        DOM.style table, zoom: w2 / w1

  showId:   0
  shownMsg: 0
  add: (msg) ->
    return if @shownMsg > 20
    @showId   += 1
    @shownMsg += 1

    if typeof msg is 'string'
      msg = {repo: 'service', note: msg}

    div = DOM.create @msgs,
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

    title = DOM.create div,
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

    content = DOM.create div,
      color:      '#eee'
      display:    'inline-block'
      fontSize:   '11px'
      lineHeight: '18px'
      padding:    '8px'
      whiteSpace: 'normal'
    content.innerHTML = msg.note or msg.msg

    for i in [1 .. 10]
      do (i) ->
        setTimeout ->
          DOM.style div, zoom: i / 10
        , i * 10

    for i in [84 .. 0] when i % 2 is 0
      do (i) ->
        setTimeout ->
          DOM.style div,
            opacity: i / 100
            left:    ((85 - i) / 85 * 255) + 'px'
        , 4825 + (85 - i) * 3

    setTimeout =>
      DOM.remove div
      @shownMsg -= 1
    , 5000
