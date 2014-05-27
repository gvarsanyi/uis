(function() {
  var Comm, DOM, HUD, Stats, comm, hud, stats,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Comm = (function() {
    Comm.prototype.cssReloadCount = 0;

    Comm.prototype.init = true;

    Comm.prototype.reconnect = false;

    Comm.prototype.reloading = false;

    Comm.prototype.serviceUp = false;

    function Comm() {
      this.processMsg = __bind(this.processMsg, this);
      var subscription;
      this.bayeux = new Faye.Client('/bayeux', {
        retry: .5
      });
      this.bayeux.on('transport:down', (function(_this) {
        return function() {
          return setTimeout(function() {
            if (!_this.serviceUp) {
              hud.add('disconnected');
              return _this.reconnect = true;
            }
          }, 1);
        };
      })(this));
      this.bayeux.on('transport:up', (function(_this) {
        return function() {
          if (!_this.init) {
            setTimeout(function() {
              if (_this.reconnect) {
                return _this.reload();
              }
            }, 1);
          }
          _this.init = false;
          return _this.serviceUp = true;
        };
      })(this));
      subscription = this.bayeux.subscribe('/update', (function(_this) {
        return function(msg) {
          var _i, _len, _ref, _results;
          _ref = stats.incoming(msg);
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            msg = _ref[_i];
            _results.push(_this.processMsg(msg));
          }
          return _results;
        };
      })(this));
      subscription.then((function(_this) {
        return function() {
          var stats_subscription;
          return stats_subscription = _this.bayeux.subscribe('/init', function(msg) {
            var _i, _len, _ref;
            stats_subscription.cancel();
            _ref = stats.init(msg.data, msg.ids);
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              msg = _ref[_i];
              _this.processMsg(msg);
            }
            return hud.render();
          });
        };
      })(this));
      this.takeOverConsole();
    }

    Comm.prototype.reload = function(msg) {
      var div;
      if (msg == null) {
        msg = 'reloading';
      }
      if (this.reloading) {
        return;
      }
      this.reloading = true;
      div = DOM.create(document.body, {
        background: '#122',
        bottom: 0,
        color: '#fff',
        left: 0,
        position: 'fixed',
        fontSize: '32px',
        lineHieght: '32px',
        fontWeight: 'bold',
        opacity: .85,
        overflow: 'hidden',
        padding: '10% 0 0 0',
        right: 0,
        textAlign: 'center',
        top: 0,
        zIndex: 2147483647
      });
      div.innerHTML = msg + '...';
      return location.reload(true);
    };

    Comm.prototype.reloadCss = function() {
      var node, src, _i, _len, _ref;
      this.cssReloadCount += 1;
      _ref = document.getElementsByTagName('link');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (src = node != null ? node.getAttribute('href') : void 0) {
          node.href = src + (src.indexOf('?') > -1 ? '&' : '?') + '___uis_refresh=' + this.cssReloadCount;
        }
      }
      return hud.add({
        repo: 'css',
        note: 'refreshed styles'
      });
    };

    Comm.prototype.processMsg = function(msg) {
      var _ref, _ref1;
      switch (msg != null ? msg.type : void 0) {
        case 'note':
          return hud.add(msg);
        case 'stat':
          if (msg.stat.done && ((_ref = msg.task) === 'deployer' || _ref === 'filesDeployer')) {
            if (msg.repo === 'css') {
              this.reloadCss();
            } else if ((_ref1 = msg.repo) === 'html' || _ref1 === 'js') {
              this.reload();
            }
          }
          return hud.render();
      }
    };

    Comm.prototype.takeOverConsole = function() {
      var orig_error, orig_log, stringify;
      stringify = function(obj) {
        if (obj && typeof obj === 'object' && (typeof JSON !== "undefined" && JSON !== null ? JSON.stringify : void 0)) {
          return JSON.stringify(obj);
        }
        return String(obj);
      };
      if (orig_log = typeof console !== "undefined" && console !== null ? console.log : void 0) {
        console._log = console.log;
        console.log = function() {
          var args, item;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          hud.add({
            repo: 'log',
            note: ((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = args.length; _i < _len; _i++) {
                item = args[_i];
                _results.push(stringify(item));
              }
              return _results;
            })()).join(' ')
          });
          return console._log.apply(console, args);
        };
      }
      if (orig_error = typeof console !== "undefined" && console !== null ? console.error : void 0) {
        console._error = console.error;
        return console.error = function() {
          var args, item;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          hud.add({
            repo: 'error',
            note: ((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = args.length; _i < _len; _i++) {
                item = args[_i];
                _results.push(stringify(item));
              }
              return _results;
            })()).join(' ')
          });
          return console._error.apply(console, args);
        };
      }
    };

    return Comm;

  })();

  DOM = (function() {
    function DOM() {}

    DOM.create = function(parent, styles, tag) {
      var node;
      if (tag == null) {
        tag = 'DIV';
      }
      try {
        parent.appendChild(node = document.createElement(tag.toUpperCase()));
        DOM.style(node, {
          border: '0 solid transparent',
          borderRadius: 0,
          boxSizing: 'border-box',
          color: '#eee',
          display: 'block',
          font: '13px normal Arial,sans-serif',
          lineHeight: '13px',
          margin: 0,
          opacity: 1,
          overflow: 'hidden',
          padding: 0,
          position: 'relative',
          verticalAlign: 'top',
          whiteSpace: 'nowrap',
          zIndex: 2147483647,
          zoom: 1
        });
        if (styles) {
          DOM.style(node, styles);
        }
      } catch (_error) {}
      return node;
    };

    DOM.remove = function(node) {
      try {
        return node.parentNode.removeChild(node);
      } catch (_error) {}
    };

    DOM.style = function(node, styles) {
      var k, v, _results;
      try {
        _results = [];
        for (k in styles) {
          v = styles[k];
          _results.push(node.style[k] = v);
        }
        return _results;
      } catch (_error) {}
    };

    return DOM;

  })();

  HUD = (function() {
    var colors, pending, ready, state_symbols;

    pending = false;

    ready = false;

    colors = {
      load: ['#18e', '#4bf', '#18e'],
      done: ['#eee', '#fff', '#eee'],
      check: ['#394', '#6c7', '#394'],
      warn: ['#e81', '#fb4', '#e81'],
      error: ['#e33', '#f66', '#e33'],
      note: ['#347', '#349', '#347']
    };

    state_symbols = {
      load: '&#8987;',
      check: '&#10003;',
      done: '&#10003;',
      warn: '&#9888;',
      error: '&#10007;',
      note: '&#9432;'
    };

    function HUD() {
      this.render = __bind(this.render, this);
      var loaded;
      loaded = (function(_this) {
        return function() {
          ready = true;
          if (pending) {
            _this.render();
          }
          return pending = false;
        };
      })(this);
      document.addEventListener('DOMContentLoaded', loaded, false);
      window.addEventListener('load', loaded, false);
    }

    HUD.prototype.render = function() {
      var anim, code, col, content, cut, dir, ext, file, has_title, i, line, line_chars, lines, msg, n, node, parts, push, row, row_n, spc, state, status, table, td, th, tr, w1, w2, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m, _n, _o, _p, _ref, _ref1, _ref10, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      if (!ready) {
        return pending = true;
      }
      if (!this.div) {
        this.panel = DOM.create(document.body, {
          bottom: '5px',
          position: 'fixed',
          right: '5px',
          verticalAlign: 'bottom',
          maxWidth: '20%'
        });
        this.msgs = DOM.create(this.panel);
        this.info = DOM.create(this.panel);
        this.div = DOM.create(document.body, {
          background: 'linear-gradient(#122, #233, #122)',
          border: '#011 solid 1px',
          borderBottom: 'solid 0px transparent',
          borderRight: 'solid 0px transparent',
          borderRadius: '32px 0 0 0',
          bottom: 0,
          height: '24px',
          position: 'fixed',
          right: 0,
          verticalAlign: 'bottom',
          width: '24px'
        });
        this.state = DOM.create(this.div, {
          color: '#0a1616',
          fontSize: '18px',
          height: '18px',
          lineHeight: '18px',
          position: 'absolute',
          right: 0,
          top: '4px',
          textAlign: 'center',
          textShadow: '1px 1px #000',
          width: '18px',
          '@-moz-keyframes': 'spin{100%{-moz-transform: rotate(360deg);}}',
          '@-webkit-keyframes': 'spin{100%{-webkit-transform: rotate(360deg);}}',
          '@keyframes': 'spin{100%{transform:rotate(360deg);}}'
        });
      }
      state = stats.state();
      this.state.innerHTML = state_symbols[state];
      anim = state === 'load' ? 'spin 1s linear infinite' : 'none';
      DOM.style(this.state, {
        '-webkit-animation': anim,
        animation: anim,
        color: colors[state][0]
      });
      DOM.style(this.title, {
        color: colors[state][0]
      });
      status = 'error';
      if (!(msg = stats.hasError())) {
        msg = stats.hasWarning();
        status = 'warn';
      }
      if (!msg) {
        return DOM.style(this.info, {
          display: 'none'
        });
      } else {
        this.info.innerHTML = '';
        DOM.style(this.info, {
          background: '#233',
          borderLeft: colors[status][0] + ' groove 2px',
          borderRadius: '3px',
          display: 'block',
          margin: '3px',
          maxHeight: '250px',
          overflowX: 'hidden',
          overflowY: 'auto',
          padding: '3px',
          width: '100%'
        });
        if (msg.title) {
          node = DOM.create(this.info, {
            background: '#455',
            fontWeight: 'bold',
            padding: '2px',
            whiteSpace: 'normal'
          });
          node.innerHTML = msg.title;
        }
        if (msg.description) {
          node = DOM.create(this.info, {
            padding: '4px 2px',
            whiteSpace: 'pre'
          });
          node.innerHTML = msg.description;
        }
        if (msg.file) {
          node = DOM.create(this.info, {
            background: '#344',
            borderRadius: '3px',
            color: '#ddd',
            fontWeight: 'bold',
            padding: '3px'
          });
          if (msg.lines) {
            DOM.style(node, {
              border: 'solid 1px #455',
              borderBottom: 'solid 1px #233',
              borderRadius: '3px 3px 0 0'
            });
          }
          node.innerHTML = msg.file;
          if (msg.line && !msg.lines) {
            if (typeof msg.line === 'object') {
              node.innerHTML += ' @ lines ' + msg.line.join('-');
            } else {
              node.innerHTML += ' @ line ' + msg.line;
            }
          }
        }
        if (msg.table) {
          table = DOM.create(this.info, {
            background: '#233',
            display: 'table',
            tableLayout: 'fixed'
          }, 'table');
          has_title = false;
          _ref = msg.table.columns;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            col = _ref[_i];
            if (col.align !== 'right') {
              col.align = 'left';
            }
            if (col.title != null) {
              has_title = true;
            }
          }
          if (has_title) {
            tr = DOM.create(table, {
              display: 'table-row'
            }, 'tr');
            _ref1 = msg.table.columns;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              col = _ref1[_j];
              th = DOM.create(tr, {
                background: '#344',
                borderSpacing: '1px',
                color: '#eee',
                display: 'table-cell',
                fontWeight: 'bold',
                padding: '2px',
                textAlign: col.align,
                width: col.width || 'auto'
              }, 'th');
              if (col.title != null) {
                th.innerHTML = col.title;
              }
            }
          }
          _ref2 = msg.table.data;
          for (row_n = _k = 0, _len2 = _ref2.length; _k < _len2; row_n = ++_k) {
            row = _ref2[row_n];
            tr = DOM.create(table, {
              display: 'table-row'
            }, 'tr');
            _ref3 = msg.table.columns;
            for (i = _l = 0, _len3 = _ref3.length; _l < _len3; i = ++_l) {
              col = _ref3[i];
              td = DOM.create(tr, {
                background: (row_n % 2 ? '#485a5a' : '#455'),
                borderSpacing: '1px',
                color: '#eee',
                display: 'table-cell',
                padding: '2px',
                textAlign: col.align,
                width: col.width || 'auto'
              }, 'td');
              content = col.src != null ? row[col.src] : row[i];
              switch (col.highlight) {
                case 'basename':
                  parts = content.split('/');
                  file = parts.pop();
                  dir = parts.length ? parts.join('/') + '/' : '';
                  parts = file.split('.');
                  file = parts.shift();
                  ext = parts.length ? '.' + parts.join('.') : '';
                  content = file;
                  if (dir) {
                    content = '<span style="color: #999">' + dir + '</span>' + content;
                  }
                  if (ext) {
                    content += '<span style="font-size: 9px; color: #999">' + ext + '</span>';
                  }
              }
              td.innerHTML = content;
            }
          }
        }
        if (msg.lines) {
          lines = DOM.create(this.info, {
            background: '#455',
            color: '#eee',
            left: 0,
            margin: '2px 0 0 0',
            position: 'absolute'
          });
          for (n = _m = _ref4 = msg.lines.from, _ref5 = msg.lines.to; _ref4 <= _ref5 ? _m <= _ref5 : _m >= _ref5; n = _ref4 <= _ref5 ? ++_m : --_m) {
            if (msg.lines[n] != null) {
              line = DOM.create(lines, {
                color: '#eee',
                fontFamily: '"Lucida Console", Monaco, monospace',
                padding: '0 4px 0 2px',
                textAlign: 'right',
                whiteSpace: 'pre'
              });
              if (n === msg.line || (typeof msg.line === 'object' && __indexOf.call(msg.line, n) >= 0)) {
                DOM.style(line, {
                  background: '#633'
                });
              }
              line.innerHTML = n;
            }
          }
          line_chars = 0;
          for (n = _n = _ref6 = msg.lines.from, _ref7 = msg.lines.to; _ref6 <= _ref7 ? _n <= _ref7 : _n >= _ref7; n = _ref6 <= _ref7 ? ++_n : --_n) {
            if (msg.lines[n] != null) {
              line_chars = Math.max(line_chars, String(n).length);
            }
          }
          push = line_chars * 10 + 10;
          node = DOM.create(this.info, {
            background: '#455',
            padding: '2px 2px 2px ' + push + 'px',
            overflow: 'auto',
            zIndex: 2147483646
          });
          for (n = _o = _ref8 = msg.lines.from, _ref9 = msg.lines.to; _ref8 <= _ref9 ? _o <= _ref9 : _o >= _ref9; n = _ref8 <= _ref9 ? ++_o : --_o) {
            if ((code = msg.lines[n]) != null) {
              line = DOM.create(node, {
                color: '#eee',
                fontFamily: '"Lucida Console", Monaco, monospace',
                overflow: 'visible',
                whiteSpace: 'pre'
              });
              if (n === msg.line || (typeof msg.line === 'object' && __indexOf.call(msg.line, n) >= 0)) {
                DOM.style(line, {
                  fontWeight: 'bold',
                  color: '#e66'
                });
              }
              code = code.split('\t').join('    ');
              cut = 0;
              for (i = _p = _ref10 = code.length - 1; _ref10 <= 0 ? _p <= 0 : _p >= 0; i = _ref10 <= 0 ? ++_p : --_p) {
                if (code[i] === ' ') {
                  cut += 1;
                } else {
                  break;
                }
              }
              if (cut) {
                spc = '<span style="background: #766;">' + code.substr(code.length - cut) + '</span>';
                code = code.substr(0, code.length - cut) + spc;
              }
              line.innerHTML = code || ' ';
            }
          }
        }
        if (table && (w1 = table.offsetWidth) > (w2 = this.info.offsetWidth - 28)) {
          return DOM.style(table, {
            zoom: w2 / w1
          });
        }
      }
    };

    HUD.prototype.showId = 0;

    HUD.prototype.shownMsg = 0;

    HUD.prototype.add = function(msg) {
      var content, div, i, status, title, _fn, _i, _j;
      if (this.shownMsg > 20) {
        return;
      }
      this.showId += 1;
      this.shownMsg += 1;
      if (typeof msg === 'string') {
        msg = {
          repo: 'srv',
          note: msg
        };
      }
      div = DOM.create(this.msgs, {
        background: 'linear-gradient(#122, #233, #122)',
        borderBottom: '#000 solid 1px',
        borderRadius: '10px',
        margin: '3px 0 0',
        opacity: .85,
        overflow: 'hidden',
        paddingRight: '9px',
        zoom: .01
      });
      status = 'note';
      if (msg.repo === 'error') {
        status = 'error';
      }
      if (msg.repo === 'log') {
        status = 'warn';
      }
      title = DOM.create(div, {
        background: 'linear-gradient(' + colors[status].join(', ') + ')',
        border: '#122 solid 1px',
        borderRadius: '10px',
        color: '#f8f8f8',
        display: 'inline-block',
        fontWeight: 'bold',
        fontSize: '11px',
        height: '18px',
        lineHeight: '18px',
        padding: '0 9px',
        textAlign: 'center'
      });
      title.innerHTML = msg.repo.toUpperCase();
      content = DOM.create(div, {
        color: '#eee',
        display: 'inline-block',
        fontSize: '11px',
        lineHeight: '18px',
        padding: '8px',
        whiteSpace: 'normal'
      });
      content.innerHTML = msg.note;
      _fn = function(i) {
        return setTimeout(function() {
          return DOM.style(div, {
            zoom: i / 10
          });
        }, i * 10);
      };
      for (i = _i = 1; _i <= 10; i = ++_i) {
        _fn(i);
      }
      for (i = _j = 84; _j >= 0; i = --_j) {
        if (i % 2 === 0) {
          (function(i) {
            return setTimeout(function() {
              return DOM.style(div, {
                opacity: i / 100,
                left: ((85 - i) / 85 * 255) + 'px'
              });
            }, 4825 + (85 - i) * 3);
          })(i);
        }
      }
      return setTimeout((function(_this) {
        return function() {
          DOM.remove(div);
          return _this.shownMsg -= 1;
        };
      })(this), 5000);
    };

    return HUD;

  })();

  Stats = (function() {
    var cue_processor, message_cue, ready_list;

    function Stats() {
      this.incoming = __bind(this.incoming, this);
      this.state = __bind(this.state, this);
      this.isDone = __bind(this.isDone, this);
      this.hasWarning = __bind(this.hasWarning, this);
      this.hasError = __bind(this.hasError, this);
      this.repos = __bind(this.repos, this);
      this.init = __bind(this.init, this);
    }

    message_cue = {};

    cue_processor = function(msg) {
      var cue, id, repo, task, _base, _base1, _ref, _ref1;
      if (!(typeof msg.id === 'number' && msg.id >= 0)) {
        throw new Error('invalid/missing msg id: ' + msg);
      }
      repo = msg.repo;
      task = msg.task;
      if (msg.type === 'note') {
        repo = task = 'note';
      }
      if (!(repo && task)) {
        throw new Error('invalid/missing msg.repo and/or msg.task: ' + msg);
      }
      if (message_cue[repo] == null) {
        message_cue[repo] = {};
      }
      if ((_base = message_cue[repo])[task] == null) {
        _base[task] = [];
      }
      id = typeof stats !== "undefined" && stats !== null ? (_ref = stats.ids) != null ? (_ref1 = _ref[repo]) != null ? _ref1[task] : void 0 : void 0 : void 0;
      if ((id != null) && id >= msg.id) {
        return comm.reload('server restarting');
      }
      if ((typeof stats !== "undefined" && stats !== null ? stats.data : void 0) && ((id == null) || msg.id === id + 1)) {
        if ((_base1 = stats.ids)[repo] == null) {
          _base1[repo] = {};
        }
        stats.ids[repo][task] = msg.id;
        return [msg];
      }
      (cue = message_cue[repo][task]).push(msg);
      cue.sort(function(a, b) {
        return a.id - b.id;
      });
      return ready_list(repo, task);
    };

    ready_list = function(repo, task) {
      var cue, ids, list, _ref, _ref1, _ref2;
      list = [];
      cue = ((_ref = message_cue[repo]) != null ? _ref[task] : void 0) || [];
      while (cue.length && (((_ref1 = (ids = typeof stats !== "undefined" && stats !== null ? (_ref2 = stats.ids) != null ? _ref2[repo] : void 0 : void 0)) != null ? _ref1[task] : void 0) != null) && cue[0].id === ids[task] + 1) {
        ids[task] += 1;
        list.push(cue.shift());
      }
      return list;
    };

    Stats.prototype.data = null;

    Stats.prototype.ids = null;

    Stats.prototype.init = function(initial_stats, initial_ids) {
      var list, msg, repo, repo_data, task, _i, _len, _ref;
      if (!((this.data == null) && (initial_stats != null) && typeof initial_stats === 'object' && (initial_ids != null) && typeof initial_ids === 'object')) {
        throw new Error('init-stat: ' + arguments);
      }
      this.data = initial_stats;
      this.ids = initial_ids;
      list = [];
      for (repo in initial_stats) {
        repo_data = initial_stats[repo];
        for (task in repo_data) {
          _ref = ready_list(repo, task);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            msg = _ref[_i];
            list.push(msg);
          }
        }
      }
      return list;
    };

    Stats.prototype.repos = function(name) {
      var k, _results;
      if (name) {
        return [name];
      }
      _results = [];
      for (k in this.data) {
        _results.push(k);
      }
      return _results;
    };

    Stats.prototype.hasError = function(repo) {
      var inf, task, _i, _len, _ref, _ref1, _ref2;
      _ref = this.repos(repo);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo = _ref[_i];
        _ref1 = this.data[repo];
        for (task in _ref1) {
          inf = _ref1[task];
          if (!inf.muted) {
            if ((_ref2 = inf.error) != null ? _ref2.length : void 0) {
              return inf.error[0];
            }
          }
        }
      }
      return false;
    };

    Stats.prototype.hasWarning = function(repo) {
      var inf, task, _i, _len, _ref, _ref1, _ref2;
      _ref = this.repos(repo);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo = _ref[_i];
        _ref1 = this.data[repo];
        for (task in _ref1) {
          inf = _ref1[task];
          if (!inf.muted) {
            if ((_ref2 = inf.warning) != null ? _ref2.length : void 0) {
              return inf.warning[0];
            }
          }
        }
      }
      return false;
    };

    Stats.prototype.isDone = function(repo) {
      var inf, task, _i, _len, _ref, _ref1, _ref2;
      _ref = this.repos(repo);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo = _ref[_i];
        _ref1 = this.data[repo];
        for (task in _ref1) {
          inf = _ref1[task];
          if ((_ref2 = inf.error) != null ? _ref2.length : void 0) {
            continue;
          }
          if (!inf.done) {
            return false;
          }
        }
      }
      return true;
    };

    Stats.prototype.state = function(repo) {
      var state;
      state = 'load';
      if (this.hasError(repo)) {
        state = 'error';
      } else if (this.hasWarning(repo)) {
        state = 'warn';
      } else if (this.isDone(repo)) {
        state = 'check';
      }
      return state;
    };

    Stats.prototype.incoming = function(msg) {
      var id, msgs, _base, _base1, _i, _len, _name, _name1, _ref, _ref1;
      msgs = cue_processor(msg);
      for (_i = 0, _len = msgs.length; _i < _len; _i++) {
        msg = msgs[_i];
        if (msg.type === 'stat') {
          if (((id = (_ref = this.ids) != null ? (_ref1 = _ref[msg.repo]) != null ? _ref1[msg.task] : void 0 : void 0) == null) || id <= msg.id) {
            if ((_base = this.data)[_name = msg.repo] == null) {
              _base[_name] = {};
            }
            this.data[msg.repo][msg.task] = msg.stat;
            if ((_base1 = this.ids)[_name1 = msg.repo] == null) {
              _base1[_name1] = {};
            }
            this.ids[msg.repo][msg.task] = msg.id;
          }
        }
      }
      return msgs;
    };

    return Stats;

  })();

  stats = new Stats;

  hud = new HUD;

  comm = new Comm;

}).call(this);
