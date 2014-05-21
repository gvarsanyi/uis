// Generated by CoffeeScript 1.7.1
(function() {
  var boxlines, icons, info_out, ngroup, obj_to_str, print, subitem, timestamp, types,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  ngroup = require('../ngroup');

  types = require('../stat-types');

  timestamp = function() {
    var fix, t;
    fix = function(n, digits) {
      if (digits == null) {
        digits = 2;
      }
      while (String(n).length < digits) {
        n = '0' + n;
      }
      return n;
    };
    return (t = new Date()).getHours() + ':' + fix(t.getMinutes()) + ':' + fix(t.getSeconds()) + '.' + fix(t.getMilliseconds(), 3);
  };

  icons = {
    start: '⚐',
    check: '✔',
    error: '✗',
    warning: '⚠',
    working: '⌛'
  };

  subitem = '↳';

  boxlines = {
    h: '─',
    v: '│',
    x: '┼'
  };

  print = function() {
    var icon, msg, output, repo, status, task;
    status = arguments[0], repo = arguments[1], task = arguments[2], msg = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    icon = ' ' + (icons[status] || ' ');
    output = status === 'error' ? 'error' : 'log';
    repo = ' [' + repo + ']';
    while (repo.length < 7) {
      repo = ' ' + repo;
    }
    return console[output].apply(console, [timestamp() + repo + icon + ' ' + task].concat(__slice.call(msg)));
  };

  obj_to_str = function(status, inf) {
    var indent, n, out, pre, push, table, _i, _ref, _ref1;
    table = function(table, push) {
      var align, col, has_title, i, msg, row, row_n, txt, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
      if (push == null) {
        push = 0;
      }
      align = {
        left: function(str, size, chr) {
          if (chr == null) {
            chr = ' ';
          }
          str = String(str);
          while (str.length < size) {
            str += chr;
          }
          return str;
        },
        right: function(str, size, chr) {
          if (chr == null) {
            chr = ' ';
          }
          str = String(str);
          while (str.length < size) {
            str = chr + str;
          }
          return str;
        }
      };
      msg = '\n';
      if (!push) {
        push = '';
      } else {
        push = align.left('', push);
      }
      has_title = false;
      _ref = table.columns;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        col = _ref[i];
        col.width = 0;
        if (col.align !== 'right') {
          col.align = 'left';
        }
        if (col.title != null) {
          col.width = String(col.title).length;
          has_title = true;
        }
        _ref1 = table.data;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          row = _ref1[_j];
          txt = col.src != null ? row[col.src] : row[i];
          col.width = Math.max(col.width, String(txt).length);
        }
      }
      if (has_title) {
        _ref2 = table.columns;
        for (i = _k = 0, _len2 = _ref2.length; _k < _len2; i = ++_k) {
          col = _ref2[i];
          msg += i ? ' ' + boxlines.v + ' ' : push + ' ';
          msg += align[col.align](col.title || '', col.width);
        }
        msg += '\n';
        _ref3 = table.columns;
        for (i = _l = 0, _len3 = _ref3.length; _l < _len3; i = ++_l) {
          col = _ref3[i];
          msg += i ? boxlines.h + boxlines.x + boxlines.h : push + boxlines.h;
          msg += align.left('', col.width, boxlines.h);
        }
        msg += boxlines.h + ' \n';
      }
      _ref4 = table.data;
      for (row_n = _m = 0, _len4 = _ref4.length; _m < _len4; row_n = ++_m) {
        row = _ref4[row_n];
        _ref5 = table.columns;
        for (i = _n = 0, _len5 = _ref5.length; _n < _len5; i = ++_n) {
          col = _ref5[i];
          msg += i ? ' ' + boxlines.v + ' ' : push + ' ';
          txt = col.src != null ? row[col.src] : row[i];
          msg += align[col.align](txt, col.width);
        }
        msg += '\n';
      }
      return msg;
    };
    if (!inf.file) {
      '[' + status.toUpperCase() + '] ' + String(inf) + '\n';
    }
    out = '[' + status.toUpperCase() + '] ' + (inf.file || '') + (inf.line ? ' @ line ' + inf.line : '') + '\n';
    indent = '  ';
    if (inf.lines) {
      for (n = _i = _ref = inf.lines.from, _ref1 = inf.lines.to; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; n = _ref <= _ref1 ? ++_i : --_i) {
        if (inf.lines[n] != null) {
          push = String(n).length < String(inf.lines.to).length ? ' ' : '';
          pre = indent;
          if (n === inf.line || (typeof inf.line === 'object' && __indexOf.call(inf.line, n) >= 0)) {
            pre = pre.split(' ').join('>');
          }
          out += pre + '(' + n + ') ' + inf.lines[n] + '\n';
        }
      }
    }
    if (inf.title) {
      out += indent + inf.title + '\n';
    }
    if (inf.description) {
      out += indent + '  ' + subitem + ' ' + inf.description.split('\n').join('\n    ' + indent) + '\n';
    }
    if (inf.table != null) {
      out += table(inf.table, 4);
    }
    return out;
  };

  info_out = function(status, inf) {
    var block, output, part, _i, _len, _results;
    output = status === 'error' ? 'error' : 'log';
    console[output]('');
    _results = [];
    for (_i = 0, _len = inf.length; _i < _len; _i++) {
      block = inf[_i];
      if (block instanceof Array) {
        _results.push((function() {
          var _j, _len1, _results1;
          _results1 = [];
          for (_j = 0, _len1 = block.length; _j < _len1; _j++) {
            part = block[_j];
            _results1.push(console[output](obj_to_str(status, part)));
          }
          return _results1;
        })());
      } else {
        _results.push(console[output](obj_to_str(status, block)));
      }
    }
    return _results;
  };

  module.exports.update = function(update) {
    var count, done, error, error_state, msg, size, status, warning, _ref;
    _ref = update.stat, done = _ref.done, count = _ref.count, error = _ref.error, warning = _ref.warning, size = _ref.size, status = _ref.status;
    error_state = 'start';
    if (done) {
      error_state = 'check';
    }
    if (warning) {
      error_state = 'warning';
    }
    if (error) {
      error_state = 'error';
    }
    if (done || error || warning) {
      msg = '';
      if (error != null) {
        msg = ': ' + ngroup(error.length, 'error');
      }
      if (warning != null) {
        msg += msg ? ', ' : ': ';
        msg += ngroup(warning.length, 'warning');
      }
      if (update.task === 'tester' && size) {
        msg += msg ? ' of ' : ': ';
        msg += ngroup(size, 'test');
      } else if (size && typeof size === 'number') {
        msg += msg ? ', ' : ': ';
        msg += ngroup(size, 'byte');
      }
      if (update.task.substr(0, 5) === 'files' && status) {
        msg += msg ? ', ' : ': ';
        msg += ngroup(status, 'file');
      }
      print(error_state, update.repo, (types[update.task] || update.task) + msg);
      if (error != null) {
        info_out('error', error);
      }
      if (warning != null) {
        return info_out('warning', warning);
      }
    }
  };

  module.exports.log = function(msg) {
    var out;
    out = String(msg.msg);
    return console.log('[' + msg.repo + ']', out.substr(0, out.length - 1));
  };

  module.exports.error = function(msg) {
    var out;
    out = String(msg.msg);
    return console.error('[' + msg.repo + '] ERROR', out.substr(0, out.length - 1));
  };

}).call(this);
