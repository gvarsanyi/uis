// Generated by CoffeeScript 1.7.1
(function() {
  var argv, camelize, copy_opts, cwd, env, fs, load, minimist, options, _i, _len, _ref;

  fs = require('fs');

  minimist = require('minimist');

  require('coffee-script/register');

  camelize = function(str) {
    return str.replace(/-([a-z])/g, function(g) {
      return g[1].toUpperCase();
    });
  };

  copy_opts = function(from, to, from_str) {
    var k, v, _results;
    _results = [];
    for (k in from) {
      v = from[k];
      k = camelize(k);
      if (v && typeof v === 'object' && to[k] && typeof to[k] === 'object') {
        _results.push(copy_opts(v, to[k], from_str));
      } else if (from_str) {
        try {
          _results.push(to[k] = JSON.parse(v));
        } catch (_error) {
          _results.push(to[k] = v);
        }
      } else {
        _results.push(to[k] = v);
      }
    }
    return _results;
  };

  load = function(env) {
    var ext, opts, _i, _len, _ref;
    if (env == null) {
      env = '';
    }
    if (env) {
      env = '.' + env;
    }
    _ref = ['coffee', 'js', 'json'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      ext = _ref[_i];
      try {
        opts = require(cwd + '/uis' + env + '.conf.' + ext);
        break;
      } catch (_error) {}
    }
    if (!opts) {
      console.error('Missing uis' + env + '.conf.[coffee|js|json] file');
      process.exit(1);
    }
    return copy_opts(opts, options);
  };

  options = module.exports;

  cwd = process.cwd();

  load();

  argv = minimist(process.argv.slice(2));

  _ref = argv._ || [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    env = _ref[_i];
    load(env);
  }

  delete argv._;

  copy_opts(argv, options, true);

}).call(this);
