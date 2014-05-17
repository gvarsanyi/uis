// Generated by CoffeeScript 1.7.1
(function() {
  var HUD, Stats, add, bayeux, colors, create, cue_processor, hud, init, message_cue, msg_div, msgs, orig_error, orig_log, process_msg, ready_list, reattach, reconnect, reload, reload_css, reload_i, reloading, remove, service_up, show, show_id, stats, stringify, style, subscription, symbols,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

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
      return reload('server restarting');
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

  Stats = (function() {
    function Stats() {
      this.incoming = __bind(this.incoming, this);
      this.init = __bind(this.init, this);
    }

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

  HUD = (function() {
    var div, pending, ready, repos;

    div = null;

    repos = {};

    pending = false;

    ready = false;

    function HUD() {
      this.render = __bind(this.render, this);
      var loaded, sticky;
      sticky = (function(_this) {
        return function() {
          reattach(div);
          show();
          return setTimeout(sticky, 33);
        };
      })(this);
      loaded = (function(_this) {
        return function() {
          ready = true;
          if (pending) {
            _this.render();
          }
          pending = false;
          return sticky();
        };
      })(this);
      document.addEventListener('DOMContentLoaded', loaded, false);
      window.addEventListener('load', loaded, false);
    }

    HUD.prototype.render = function() {
      var add_info, hidden_issues, info, issue, issue_cue, n, out, pt, repo, repo_status, shown_issues, stat, status, t, task, tasks, touched, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9, _results;
      if (!ready) {
        return pending = true;
      }
      if (!reattach(div)) {
        div = create(document.body, {
          position: 'fixed',
          left: 0,
          bottom: 0,
          width: '80%'
        });
      }
      _ref = stats.data;
      _results = [];
      for (repo in _ref) {
        tasks = _ref[repo];
        if (!(pt = repos[repo])) {
          pt = repos[repo] = {};
          pt.div = create(div, {
            background: 'linear-gradient(#122, #233, #122)',
            border: '#011 solid 1px',
            borderBottom: 'solid 0px transparent',
            borderRadius: '17px 3px 3px 3px',
            bottom: 0,
            display: 'inline-block',
            margin: '0 1%',
            maxWidth: '40%',
            opacity: .85,
            paddingRight: '2px',
            verticalAlign: 'bottom'
          });
          pt.title = create(pt.div, {
            background: 'linear-gradient(#374, #394, #374)',
            border: '#122 solid 1px',
            borderBottom: 'transparent 0 solid',
            borderRadius: '17px 3px 17px 3px',
            color: '#f8f8f8',
            display: 'inline-block',
            fontSize: '11px',
            fontWeight: 'bold',
            height: '20px',
            left: '-2px',
            lineHeight: '18px',
            marginRight: '2px',
            padding: '0 9px',
            textAlign: 'center',
            top: '-1px'
          });
          pt.title.innerHTML = repo.toUpperCase();
          pt.head = create(pt.div, {
            display: 'inline-block',
            lineHeight: '18px'
          });
          pt.info = create(pt.div);
          pt.error = create(pt.info);
          pt.warn = create(pt.info);
        }
        for (task in tasks) {
          stat = tasks[task];
          if (symbols[task] && stat.count) {
            if (!pt[task]) {
              for (t in symbols) {
                if (!pt[t]) {
                  continue;
                }
                remove(pt[t]);
                delete pt[t];
              }
              break;
            }
          }
        }
        repo_status = 'done';
        pt.error.innerHTML = '';
        pt.warn.innerHTML = '';
        touched = {};
        shown_issues = 0;
        hidden_issues = 0;
        add_info = function(msg, status) {
          var code, cut, i, line, line_chars, lines, n, node, panel, push, spc, _i, _j, _k, _l, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _results1;
          if (status == null) {
            status = 'warn';
          }
          if (shown_issues > 2) {
            hidden_issues += 1;
            return;
          }
          shown_issues += 1;
          if (touched[status]) {
            create(pt[status], null, 'br');
          }
          touched[status] = true;
          panel = create(pt[status], {
            background: '#233',
            borderLeft: colors[status][0] + ' groove 2px',
            borderRadius: '3px',
            display: 'inline-block',
            margin: '3px',
            padding: '3px',
            width: '100%'
          });
          if (msg.title) {
            node = create(panel, {
              background: '#455',
              fontWeight: 'bold',
              padding: '2px',
              whiteSpace: 'normal'
            });
            node.innerHTML = msg.title;
          }
          if (msg.description) {
            node = create(panel, {
              padding: '4px 2px',
              whiteSpace: 'normal'
            });
            node.innerHTML = msg.description;
          }
          if (msg.file) {
            node = create(panel, {
              background: '#344',
              borderRadius: '3px',
              color: '#ddd',
              fontWeight: 'bold',
              padding: '3px'
            });
            if (msg.lines) {
              style(node, {
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
          if (msg.lines) {
            lines = create(panel, {
              background: '#455',
              color: '#eee',
              left: 0,
              margin: '2px 0 0 0',
              position: 'absolute'
            });
            for (n = _i = _ref1 = msg.lines.from, _ref2 = msg.lines.to; _ref1 <= _ref2 ? _i <= _ref2 : _i >= _ref2; n = _ref1 <= _ref2 ? ++_i : --_i) {
              if (msg.lines[n] != null) {
                line = create(lines, {
                  color: '#eee',
                  fontFamily: '"Lucida Console", Monaco, monospace',
                  padding: '0 4px 0 2px',
                  textAlign: 'right',
                  whiteSpace: 'pre'
                });
                if (n === msg.line || (typeof msg.line === 'object' && __indexOf.call(msg.line, n) >= 0)) {
                  style(line, {
                    background: '#633'
                  });
                }
                line.innerHTML = n;
              }
            }
            line_chars = 0;
            for (n = _j = _ref3 = msg.lines.from, _ref4 = msg.lines.to; _ref3 <= _ref4 ? _j <= _ref4 : _j >= _ref4; n = _ref3 <= _ref4 ? ++_j : --_j) {
              if (msg.lines[n] != null) {
                line_chars = Math.max(line_chars, String(n).length);
              }
            }
            push = line_chars * 10 + 10;
            node = create(panel, {
              background: '#455',
              padding: '2px 2px 2px ' + push + 'px',
              overflow: 'auto',
              zIndex: 2147483646
            });
            _results1 = [];
            for (n = _k = _ref5 = msg.lines.from, _ref6 = msg.lines.to; _ref5 <= _ref6 ? _k <= _ref6 : _k >= _ref6; n = _ref5 <= _ref6 ? ++_k : --_k) {
              if ((code = msg.lines[n]) != null) {
                line = create(node, {
                  color: '#eee',
                  fontFamily: '"Lucida Console", Monaco, monospace',
                  overflow: 'visible',
                  whiteSpace: 'pre'
                });
                if (n === msg.line || (typeof msg.line === 'object' && __indexOf.call(msg.line, n) >= 0)) {
                  style(line, {
                    fontWeight: 'bold',
                    color: '#e66'
                  });
                }
                code = code.split('\t').join('    ');
                cut = 0;
                for (i = _l = _ref7 = code.length - 1; _ref7 <= 0 ? _l <= 0 : _l >= 0; i = _ref7 <= 0 ? ++_l : --_l) {
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
                _results1.push(line.innerHTML = code || ' ');
              } else {
                _results1.push(void 0);
              }
            }
            return _results1;
          }
        };
        issue_cue = [];
        for (task in symbols) {
          if ((_ref1 = (stat = tasks[task])) != null ? _ref1.count : void 0) {
            if (!pt[task]) {
              pt[task] = create(pt.head, {
                display: 'inline-block',
                fontWeight: 'bold',
                fontSize: '11px',
                lineHeight: '18px',
                margin: '0 4px'
              });
            }
            out = symbols[task];
            status = 'load';
            if (stat.done) {
              status = 'done';
            }
            if (n = (_ref2 = stat.error) != null ? _ref2.length : void 0) {
              status = 'error';
              out += ':' + n;
              _ref3 = stat.error;
              for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
                info = _ref3[_i];
                issue_cue.push({
                  level: 'error',
                  info: info
                });
              }
              if (n = (_ref4 = stat.warning) != null ? _ref4.length : void 0) {
                out += '<span style="color: ' + colors['warn'][0] + ';">+' + n + '</span>';
                _ref5 = stat.warning;
                for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
                  info = _ref5[_j];
                  issue_cue.push({
                    level: 'warn',
                    info: info
                  });
                }
              }
            } else if (n = (_ref6 = stat.warning) != null ? _ref6.length : void 0) {
              status = 'warn';
              out += ':' + n;
              _ref7 = stat.warning;
              for (_k = 0, _len2 = _ref7.length; _k < _len2; _k++) {
                info = _ref7[_k];
                issue_cue.push({
                  level: 'warn',
                  info: info
                });
              }
            }
            style(pt[task], {
              color: colors[status][0]
            });
            pt[task].innerHTML = out;
            if (repo_status === 'done') {
              repo_status = 'check';
            }
            if (!(stat.done || (repo_status === 'warn' || repo_status === 'error'))) {
              repo_status = 'load';
            }
            if (((_ref8 = stat.warning) != null ? _ref8.length : void 0) && repo_status !== 'error') {
              repo_status = 'warn';
            }
            if ((_ref9 = stat.error) != null ? _ref9.length : void 0) {
              repo_status = 'error';
            }
          }
        }
        issue_cue.reverse();
        issue_cue.sort(function(a, b) {
          if (a.level === 'warn') {
            return 1;
          }
          return -1;
        });
        if (issue = issue_cue[0]) {
          add_info(issue.info, issue.level);
          style(pt.div, {
            opacity: 1
          });
        }
        _results.push(style(pt.title, {
          background: 'linear-gradient(' + colors[repo_status].join(', ') + ')'
        }));
      }
      return _results;
    };

    return HUD;

  })();

  bayeux = new Faye.Client('/bayeux', {
    retry: .5
  });

  reload_i = 0;

  hud = new HUD;

  init = true;

  msg_div = null;

  msgs = [];

  reconnect = false;

  reloading = false;

  service_up = false;

  show_id = 0;

  stats = new Stats;

  reattach = function(node, parent) {
    if (parent == null) {
      parent = document.body;
    }
    if (node && node.parentNode !== parent) {
      parent.appendChild(node);
    }
    return node;
  };

  show = function() {
    if (!msgs.length) {
      if (msg_div) {
        remove(msg_div);
        msg_div = null;
      }
      return;
    }
    if (!reattach(msg_div)) {
      msg_div = create(document.body, {
        position: 'fixed',
        right: '5px',
        bottom: '5px',
        overflow: 'hidden',
        maxWidth: '20%',
        zIndex: 2147483647
      });
    }
  };

  add = function(msg) {
    var content, div, i, status, title, _fn, _i, _j;
    if (typeof msg === 'string') {
      msg = {
        repo: 'srv',
        note: msg
      };
    }
    show_id += 1;
    if (msgs.length > 20) {
      return;
    }
    msgs.push(msg);
    show();
    div = create(msg_div, {
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
    title = create(div, {
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
    content = create(div, {
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
        return div.style.zoom = i / 10;
      }, i * 10);
    };
    for (i = _i = 1; _i <= 10; i = ++_i) {
      _fn(i);
    }
    for (i = _j = 84; _j >= 0; i = --_j) {
      if (i % 2 === 0) {
        (function(i) {
          return setTimeout(function() {
            div.style.opacity = i / 100;
            return div.style.left = ((85 - i) / 85 * 255) + 'px';
          }, 4825 + (85 - i) * 3);
        })(i);
      }
    }
    return setTimeout(function() {
      remove(div);
      msgs.shift();
      return show();
    }, 5000);
  };

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
      add({
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
    console.error = function() {
      var args, item;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      add({
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

  bayeux.on('transport:down', function() {
    service_up = false;
    return setTimeout(function() {
      if (!service_up) {
        add('disconnected');
        return reconnect = true;
      }
    }, 1);
  });

  bayeux.on('transport:up', function() {
    if (!init) {
      setTimeout(function() {
        if (reconnect) {
          return reload();
        }
      }, 1);
    }
    init = false;
    return service_up = true;
  });

  reload = function(msg) {
    var div;
    if (msg == null) {
      msg = 'reloading';
    }
    if (reloading) {
      return;
    }
    reloading = true;
    div = create(document.body, {
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

  create = function(parent, styles, tag) {
    var node;
    if (tag == null) {
      tag = 'DIV';
    }
    try {
      parent.appendChild(node = document.createElement(tag.toUpperCase()));
      style(node, {
        border: '0 solid transparent',
        borderRadius: 0,
        color: '#eee',
        font: '13px normal Arial,sans-serif',
        lineHeight: '13px',
        margin: 0,
        opacity: 1,
        overflow: 'hidden',
        padding: 0,
        position: 'relative',
        verticalAlign: 'top',
        whiteSpace: 'nowrap',
        zIndex: 2147483647
      });
      if (styles) {
        style(node, styles);
      }
    } catch (_error) {}
    return node;
  };

  remove = function(node) {
    try {
      return node.parentNode.removeChild(node);
    } catch (_error) {}
  };

  style = function(node, styles) {
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

  hud = new HUD;

  symbols = {
    filesLoader: 'load',
    filesCompiler: 'compile',
    concatenator: 'concat',
    filesMinifier: 'minify',
    minifier: 'minify',
    filesDeployer: 'deploy',
    deployer: 'deploy',
    filesLinter: 'lint',
    tester: 'test'
  };

  colors = {
    load: ['#001', '#114', '#001'],
    done: ['#eee', '#fff', '#eee'],
    check: ['#394', '#6c7', '#394'],
    warn: ['#e81', '#fb4', '#e81'],
    error: ['#e33', '#f66', '#e33'],
    note: ['#347', '#349', '#347']
  };

  reload_css = function() {
    var node, src, _i, _len, _ref;
    reload_i += 1;
    _ref = document.getElementsByTagName('link');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      if (src = node != null ? node.getAttribute('href') : void 0) {
        node.href = src + (src.indexOf('?') > -1 ? '&' : '?') + '___uis_refresh=' + reload_i;
      }
    }
    return add({
      repo: 'css',
      note: 'refreshed styles'
    });
  };

  process_msg = function(msg) {
    var _ref;
    switch (msg != null ? msg.type : void 0) {
      case 'note':
        return add(msg);
      case 'stat':
        if (msg.stat.done && ((_ref = msg.task) === 'deployer' || _ref === 'filesDeployer') && msg.repo !== 'test') {
          if (msg.repo === 'css') {
            reload_css();
          } else {
            reload();
          }
        }
        return hud.render();
    }
  };

  subscription = bayeux.subscribe('/update', function(msg) {
    var _i, _len, _ref, _results;
    _ref = stats.incoming(msg);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      msg = _ref[_i];
      _results.push(process_msg(msg));
    }
    return _results;
  });

  subscription.then(function() {
    var stats_subscription;
    return stats_subscription = bayeux.subscribe('/init', function(msg) {
      var _i, _len, _ref;
      stats_subscription.cancel();
      _ref = stats.init(msg.data, msg.ids);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        msg = _ref[_i];
        process_msg(msg);
      }
      return hud.render();
    });
  });

}).call(this);
