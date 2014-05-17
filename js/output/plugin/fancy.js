// Generated by CoffeeScript 1.7.1
(function() {
  var Outblock, esc, first, head_shown, heads, hourglass, ngroup, outblock, print_block, shown, stats, types;

  Outblock = require('../outblock');

  ngroup = require('../ngroup');

  stats = require('../../stats');

  types = require('../stat-types');

  console.log('');

  outblock = null;

  esc = String.fromCharCode(27);

  first = true;

  hourglass = '⌛';

  heads = {
    css: ['    ╔═╗╔═╗╔═╗  ', '    ║  ╚═╗╚═╗', '    ╚═╝╚═╝╚═╝'],
    html: [' ╦ ╦╔╦╗╔╦╗╦    ', ' ╠═╣ ║ ║║║║', ' ╩ ╩ ╩ ╩ ╩╩═╝'],
    js: ['         ╦╔═╗  ', '         ║╚═╗', '       ╚═╝╚═╝'],
    test: [' ╔╦╗╔═╗╔═╗╔╦╗  ', '  ║ ╠╣ ╚═╗ ║', '  ╩ ╚═╝╚═╝ ╩']
  };

  print_block = function(push_x, push_y, title, inf, prev_inf) {
    var has_n, n, plural, working, _ref, _ref1, _ref2, _ref3;
    working = ((inf.status != null) && inf.status < inf.count) || (prev_inf == null) || (prev_inf.status && prev_inf.status === prev_inf.count && !prev_inf.error);
    if ((inf.status != null) || working) {
      outblock.bgcolor([36, 36, 36]);
    } else {
      outblock.color([50, 50, 50]).bgcolor([12, 12, 12]);
    }
    outblock.pos(push_x, push_y).write(title, 20).reset().pos(push_x, push_y + 1).write('', 20).pos(push_x, push_y + 2).write('', 20).pos(push_x, push_y + 1);
    if (working) {
      outblock.color([86, 86, 86]).write(hourglass, prev_inf).x(push_x).reset();
    }
    has_n = '';
    if (inf.status) {
      n = ngroup(inf.status - (((_ref = inf.warning) != null ? _ref.length : void 0) || 0) - (((_ref1 = inf.error) != null ? _ref1.length : void 0) || 0));
      outblock.color([220, 220, 220]).write(n);
      has_n = '+';
    }
    if ((_ref2 = inf.warning) != null ? _ref2.length : void 0) {
      n = ngroup(inf.warning.length);
      outblock.write(has_n).color([255, 159, 63]).write(n);
      has_n = '+';
    }
    if ((_ref3 = inf.error) != null ? _ref3.length : void 0) {
      n = ngroup(inf.error.length);
      outblock.write(has_n).color([255, 20, 20]).write(n);
      has_n = '+';
    }
    if (has_n) {
      plural = inf.status > 1 ? 's' : '';
      outblock.color([63, 63, 63]).write(' file' + plural);
    }
    if (inf.watched) {
      outblock.color([63, 63, 63]).write(' + ').reset().write(ngroup(inf.watched)).color([63, 63, 63]).write(' inc');
    }
    if (title === 'test') {
      if (inf.result != null) {
        outblock.pos(push_x, push_y + 2).color([160, 160, 160]).write(inf.result, 20).reset();
      }
    } else if (inf.size) {
      outblock.pos(push_x, push_y + 2).color([160, 160, 160]).write(ngroup(inf.size)).color([63, 63, 63]).write(' b').reset();
    }
    return outblock.reset();
  };

  shown = {};

  head_shown = {};

  module.exports.update = function(update) {
    var inf, name, new_sum, orig_sum, prev_inf, push_x, push_y, repo, type, _ref, _results;
    new_sum = orig_sum = ((function() {
      var _results;
      _results = [];
      for (name in shown) {
        _results.push(name);
      }
      return _results;
    })()).length;
    for (name in stats.data) {
      if (!shown[name]) {
        new_sum += 1;
      }
    }
    if (orig_sum !== new_sum) {
      shown[name] = true;
      if (outblock != null) {
        outblock.setHeight(new_sum * 4);
        head_shown = {};
      } else {
        outblock = new Outblock(new_sum * 4);
      }
    }
    push_y = 0;
    _ref = {
      css: stats.data.css,
      html: stats.data.html,
      js: stats.data.js,
      test: stats.data.test
    };
    _results = [];
    for (name in _ref) {
      repo = _ref[name];
      if (repo) {
        prev_inf = null;
        if (head_shown[name] == null) {
          outblock.pos(0, push_y).bgcolor([36, 36, 36]).write(heads[name][0]).reset().pos(0, push_y + 1).write(heads[name][1]).pos(0, push_y + 2).write(heads[name][2]);
          head_shown[name] = true;
        }
        push_x = 15;
        for (type in repo) {
          inf = repo[type];
          print_block(push_x, push_y, types[type] || type, inf, prev_inf);
          push_x += 20;
          prev_inf = inf;
        }
      }
      _results.push(push_y += 4);
    }
    return _results;
  };

  module.exports.note = function(note) {
    var msg, name, _i, _len, _ref, _results;
    _ref = ['css', 'html', 'js', 'test'];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      if (note[name]) {
        _results.push((function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = note[name] || [];
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            msg = _ref1[_j];
            _results1.push(process.stdout.write(('[' + name + '] ' + msg).split(esc).join('\\0').substr(0, process.stdout.columns - 1) + '\r'));
          }
          return _results1;
        })());
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

}).call(this);
