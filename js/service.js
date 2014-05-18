// Generated by CoffeeScript 1.7.1
(function() {
  var Service, app, bayeux, config, express, faye, fs, messenger, patch, path, restify, server, stats,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fs = require('fs');

  path = require('path');

  express = require('express');

  faye = require('faye');

  restify = require('restify');

  config = require('./config');

  messenger = require('./messenger');

  stats = require('./stats');

  app = express();

  bayeux = null;

  server = null;

  patch = fs.readFileSync(__dirname + '/../node_modules/faye/browser/' + 'faye-browser.js', {
    encoding: 'utf8'
  }) + '\n';

  patch = patch.replace('//@ sourceMappingURL=faye-browser-min.js.map', '');

  patch += fs.readFileSync(__dirname + '/../resource/service-plugin.js', {
    encoding: 'utf8'
  });

  Service = (function() {
    Service.prototype.name = 'web-service';

    Service.prototype.deployed = 0;

    Service.prototype.pending = [];

    Service.prototype.deployFilter = function(msg) {
      var _ref, _ref1, _results;
      if (((_ref = msg.stat) != null ? _ref.done : void 0) && ((_ref1 = msg.task) === 'deployer' || _ref1 === 'filesDeployer') && msg.repo !== 'test') {
        this.deployed += 1;
        if (this.deployed > 2) {
          messenger.note('deployments ready');
          _results = [];
          while (this.pending.length) {
            _results.push(this.pending.shift()());
          }
          return _results;
        }
      }
    };

    function Service() {
      this.publish = __bind(this.publish, this);
      this.incoming = __bind(this.incoming, this);
      this.deployFilter = __bind(this.deployFilter, this);
      var contents, deploy, patch_js, proxy, repo_name, _fn, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
      _ref = ['css', 'html', 'js'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo_name = _ref[_i];
        if (!config[repo_name]) {
          this.deployed += 1;
        }
      }
      app.use((function(_this) {
        return function(req, res, next) {
          if (_this.deployed > 2) {
            return next();
          }
          return _this.pending.push(next);
        };
      })(this));
      process.on('uncaughtException', function(err) {
        var msg;
        switch (err.code) {
          case 'EADDRINUSE':
            messenger.note('port ' + config.service.port + ' is already in use');
            break;
          case 'EACCES':
            msg = config.service.port;
            if (!(process.getuid() === 0 || config.service.port > 1023)) {
              msg += ' (you need root permissions)';
            }
            messenger.note('No permission to open port ' + msg);
            break;
          default:
            messenger.note('server error: ' + err);
        }
        return process.exit(1);
      });
      app.get('/healthcheck', function(req, res) {
        res.type('json');
        return res.json(200, {
          name: process.cwd().split('/').pop(),
          memory: process.memoryUsage(),
          uptime: Math.round(process.uptime() * 1000) / 1000,
          server: {
            "interface": config.service["interface"],
            port: config.service.port
          },
          system: {
            platform: process.platform,
            architecture: process.arch
          }
        });
      });
      contents = path.resolve(config.service.contents);
      patch_js = function(deploy) {
        deploy = path.resolve(deploy);
        if (deploy.substr(0, contents.length) === contents) {
          return app.get(deploy.substr(contents.length), function(req, res) {
            return fs.readFile(deploy, {
              encoding: 'utf8'
            }, function(err, data) {
              if (err) {
                res.type('json');
                return res.json(500, {
                  error: 'Server Error: loading ' + deploy
                });
              } else {
                return res.send(patch + '\n\n' + data);
              }
            });
          });
        }
      };
      if (deploy = (_ref1 = config.js) != null ? _ref1.deploy : void 0) {
        patch_js(deploy);
      }
      if (deploy = (_ref2 = config.js) != null ? _ref2.deployMinified : void 0) {
        patch_js(deploy);
      }
      app.use(express["static"](config.service.contents));
      if (config.service.proxy) {
        if (!(config.service.proxy instanceof Array)) {
          config.service.proxy = [config.service.proxy];
        }
        _ref3 = config.service.proxy;
        _fn = function(proxy) {
          return app.all(proxy.pattern, function(req, res) {
            var client, handler, method, url;
            url = proxy.target;
            if (url.substr(url.length - 1) === '/') {
              url = url.substr(0, url.length - 1);
            }
            url += req.url;
            handler = function(err, preq, pres, data) {
              res.type('json');
              messenger.note('[proxy response] ' + ((pres != null ? pres.statusCode : void 0) || '?') + ' ' + req.method + ' ' + url);
              try {
                return res.json((pres != null ? pres.statusCode : void 0) || 500, data || {
                  error: 'Server Error'
                });
              } catch (_error) {
                try {
                  return res.json(500, {
                    error: 'Server Error'
                  });
                } catch (_error) {}
              }
            };
            client = restify.createJsonClient({
              url: url
            });
            messenger.note('[proxy request] ' + req.method + ' ' + url);
            method = req.method.toLowerCase().replace('delete', 'del');
            switch (req.method) {
              case 'POST':
              case 'PUT':
                return client[method](url, req.body, handler);
              default:
                return client[method](url, handler);
            }
          });
        };
        for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
          proxy = _ref3[_j];
          _fn(proxy);
        }
      }
      server = app.listen(config.service.port, config.service["interface"], (function(_this) {
        return function() {
          bayeux = new faye.NodeAdapter({
            mount: '/bayeux',
            timeout: 45
          });
          bayeux.attach(server);
          bayeux.on('subscribe', function(client_id, channel) {
            messenger.note('[client subscription] ' + client_id + ': ' + channel);
            if (channel === '/init') {
              return _this.publish('/init', {
                data: stats.data,
                ids: stats.ids
              });
            }
          });
          return messenger.note('listening @ ' + config.service["interface"] + ':' + config.service.port);
        };
      })(this));
    }

    Service.prototype.incoming = function(msg) {
      var msgs, _i, _len, _results;
      if (msg.type === 'stat-init') {
        msgs = stats.init(msg.data, msg.ids);
      } else {
        msgs = stats.incoming(msg);
      }
      _results = [];
      for (_i = 0, _len = msgs.length; _i < _len; _i++) {
        msg = msgs[_i];
        this.publish('/update', msg);
        _results.push(this.deployFilter(msg));
      }
      return _results;
    };

    Service.prototype.publish = function(channel, message) {
      return bayeux.getClient().publish(channel, message);
    };

    return Service;

  })();

  module.exports = new Service;

  process.on('message', module.exports.incoming);

  messenger(module.exports);

}).call(this);
