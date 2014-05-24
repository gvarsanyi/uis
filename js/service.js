// Generated by CoffeeScript 1.7.1
(function() {
  var Service, app, bayeux, bodyparser, config, express, faye, fs, messenger, path, restify, server, stats,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fs = require('fs');

  path = require('path');

  bodyparser = require('body-parser');

  express = require('express');

  faye = require('faye');

  restify = require('restify');

  config = require('./config');

  messenger = require('./messenger');

  stats = require('./stats');

  app = express();

  bayeux = null;

  server = null;

  process.on('uncaughtException', function(err) {
    var msg;
    switch (err.code) {
      case 'EADDRINUSE':
        console.error('port ' + config.service.port + ' is already in use');
        break;
      case 'EACCES':
        msg = config.service.port;
        if (!(process.getuid() === 0 || config.service.port > 1023)) {
          msg += ' (you need root permissions)';
        }
        console.error('No permission to open port', msg);
        break;
      default:
        console.error(err);
    }
    return process.exit(1);
  });

  Service = (function() {
    Service.prototype.name = 'web-service';

    Service.prototype.deployed = {};

    Service.prototype.pending = {
      css: [],
      html: [],
      js: []
    };

    function Service() {
      this.publish = __bind(this.publish, this);
      this.preloadPatch = __bind(this.preloadPatch, this);
      this.incoming = __bind(this.incoming, this);
      this.deployFilter = __bind(this.deployFilter, this);
      this.deployCheck = __bind(this.deployCheck, this);
      var contents, css_resolved, js_resolved, proxy, repo_name, _fn, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
      this.preloadPatch();
      _ref = ['css', 'html', 'js'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo_name = _ref[_i];
        if (!config[repo_name]) {
          this.deployed[repo_name] = true;
        }
      }
      app.use(bodyparser());
      app.use((function(_this) {
        return function(req, res, next) {
          var _ref1;
          switch (req.url) {
            case _this.cssDeployUrl:
              if (_this.jsDeployUrl && !_this.deployed.js) {
                return _this.pending.css.push(next);
              }
              break;
            case _this.jsDeployUrl:
              if (!(_this.deployed.js || (!_this.patch && config.service.hud))) {
                return _this.pending.js.push(next);
              }
              break;
            default:
              if ((_ref1 = req.url.split('/').pop().split('.').pop()) === 'html' || _ref1 === '') {
                if (!_this.deployed.html) {
                  return _this.pending.html.push(next);
                }
              }
          }
          return next();
        };
      })(this));
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
      contents = path.resolve(config.service.contentsDir);
      if ((_ref1 = config.css) != null ? _ref1.deploy : void 0) {
        css_resolved = path.resolve(config.css.deploy);
        if (css_resolved.substr(0, contents.length) === contents) {
          this.cssDeployUrl = css_resolved.substr(contents.length);
        }
      }
      if ((_ref2 = config.js) != null ? _ref2.deploy : void 0) {
        js_resolved = path.resolve(config.js.deploy);
        if (js_resolved.substr(0, contents.length) === contents) {
          this.jsDeployUrl = js_resolved.substr(contents.length);
        }
      }
      if (config.service.hud && this.jsDeployUrl) {
        app.get(this.jsDeployUrl, (function(_this) {
          return function(req, res) {
            return fs.readFile(js_resolved, {
              encoding: 'utf8'
            }, function(err, data) {
              if (err) {
                res.type('json');
                return res.json(500, {
                  error: 'Server Error: loading ' + js_resolved
                });
              } else {
                return res.send(_this.patch + data);
              }
            });
          };
        })(this));
      }
      app.use(express["static"](contents));
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
              if (config.service.log) {
                console.log('[proxy response] ' + ((pres != null ? pres.statusCode : void 0) || '?') + ' ' + req.method + ' ' + url);
              }
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
            if (config.service.log) {
              console.log('[proxy request] ' + req.method + ' ' + url);
            }
            method = req.method.toLowerCase().replace('delete', 'del');
            switch (req.method) {
              case 'POST':
              case 'PUT':
                console.log('req.body pre', req);
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
            if (config.service.log) {
              console.log('[client subscription] ' + client_id + ': ' + channel);
            }
            if (channel === '/init') {
              return _this.publish('/init', {
                data: stats.data,
                ids: stats.ids
              });
            }
          });
          if (config.service.log) {
            return console.log('listening @ ' + config.service["interface"] + ':' + config.service.port);
          }
        };
      })(this));
    }

    Service.prototype.deployCheck = function(repo) {
      var _results;
      if (this.deployed[repo] && (this.patch || !config.service.hud || repo !== 'js')) {
        _results = [];
        while (this.pending[repo].length) {
          _results.push(this.pending[repo].shift()());
        }
        return _results;
      }
    };

    Service.prototype.deployFilter = function(msg) {
      var _ref, _ref1, _ref2, _ref3, _ref4;
      if (this._deployed) {
        return;
      }
      if ((((_ref = msg.stat) != null ? _ref.done : void 0) || ((_ref1 = msg.stat) != null ? (_ref2 = _ref1.error) != null ? _ref2.length : void 0 : void 0)) && ((_ref3 = msg.task) === 'deployer' || _ref3 === 'filesDeployer') && ((_ref4 = msg.repo) === 'css' || _ref4 === 'html' || _ref4 === 'js')) {
        this.deployed[msg.repo] = true;
        return this.deployCheck(msg.repo);
      }
    };

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
        console.log(msg);
        this.publish('/update', msg);
        _results.push(this.deployFilter(msg));
      }
      return _results;
    };

    Service.prototype.preloadPatch = function() {
      var faye_path;
      if (config.service.hud) {
        faye_path = __dirname + '/../node_modules/faye/browser/faye-browser.js';
        return fs.readFile(faye_path, {
          encoding: 'utf8'
        }, (function(_this) {
          return function(err, src1) {
            var plugin_path;
            if (err) {
              throw new Error(err);
            }
            src1 = src1.replace('//@ sourceMappingURL=faye-browser-min.js.map', '');
            plugin_path = __dirname + '/../resource/service-plugin.js';
            fs.readFile(plugin_path, {
              encoding: 'utf8'
            }, function(err, src2) {
              if (err) {
                throw new Error(err);
              }
              return _this.patch = src1 + '\n' + src2 + '\n\n';
            });
            return _this.deployCheck('js');
          };
        })(this));
      }
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
