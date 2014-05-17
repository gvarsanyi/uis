#!/usr/bin/env node
// Generated by CoffeeScript 1.7.1
(function() {
  var child_process, config, ext, name, output, repo_count, service, stats, wrap, _fn, _i, _len, _ref, _ref1;

  child_process = require('child_process');

  config = require('./config');

  stats = require('./stats');

  if ((_ref = config.output) !== 'fancy' && _ref !== 'plain') {
    config.output = 'plain';
  }

  output = require('./output/plugin/' + config.output);

  ext = __dirname.split('/').pop() === 'coffee' ? '.coffee' : '.js';

  repo_count = 0;

  service = null;

  wrap = function(child, exit_callback) {
    var iface, _fn, _i, _len, _ref1;
    _ref1 = ['stderr', 'stdout'];
    _fn = function(iface) {
      return child[iface].on('data', function(data) {
        return process[iface].write(data);
      });
    };
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      iface = _ref1[_i];
      _fn(iface);
    }
    return child.on('exit', exit_callback);
  };

  stats.init({}, {});

  if (config.service) {
    service = child_process.fork(__dirname + '/service' + ext, {
      cwd: process.cwd(),
      silent: true
    });
    wrap(service, function(code, signal) {
      return console.log('service exited', code, signal);
    });
    service.on('message', function(msg) {
      switch (msg != null ? msg.type : void 0) {
        case 'note':
          return output.note(msg);
      }
    });
    service.send({
      type: 'stat-init',
      data: stats.data,
      ids: stats.ids
    });
  }

  _ref1 = ['js', 'css', 'html', 'test'];
  _fn = function(name) {
    var repo;
    if (config[name] && (name !== 'test' || config.js)) {
      repo = child_process.fork(__dirname + '/repo/' + name + ext, {
        cwd: process.cwd(),
        silent: true
      });
      repo_count += 1;
      wrap(repo, function(code, signal) {
        repo_count -= 1;
        if (!(repo_count && !config.service)) {
          console.log('bye');
          return process.exit(0);
        }
      });
      return repo.on('message', function(msg) {
        var msgs, _j, _len1, _name, _results;
        msgs = stats.incoming(msg);
        if (service) {
          _results = [];
          for (_j = 0, _len1 = msgs.length; _j < _len1; _j++) {
            msg = msgs[_j];
            service.send(msg);
            switch (msg != null ? msg.type : void 0) {
              case 'stat':
                if (stats[_name = msg.repo] == null) {
                  stats[_name] = {};
                }
                stats[msg.repo][msg.task] = msg.stat;
                _results.push(output.update(msg));
                break;
              case 'note':
                _results.push(output.note(msg));
                break;
              default:
                _results.push(void 0);
            }
          }
          return _results;
        }
      });
    }
  };
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    name = _ref1[_i];
    _fn(name);
  }

}).call(this);