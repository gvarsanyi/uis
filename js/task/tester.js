// Generated by CoffeeScript 1.7.1
(function() {
  var Task, Tester, config, fs, karma, messenger,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  karma = require('karma');

  Task = require('../task');

  config = require('../config');

  messenger = require('../messenger');

  Tester = (function(_super) {
    __extends(Tester, _super);

    function Tester() {
      this.work = __bind(this.work, this);
      this.size = __bind(this.size, this);
      this.condition = __bind(this.condition, this);
      return Tester.__super__.constructor.apply(this, arguments);
    }

    Tester.prototype.name = 'tester';

    Tester.prototype.listeners = Tester;

    Tester.prototype.condition = function() {
      var _ref;
      return !!config[this.source.name].files && ((_ref = this.source.tasks.filesLoader) != null ? _ref.count() : void 0);
    };

    Tester.prototype.size = function() {
      return this._result || 0;
    };

    Tester.prototype.work = function() {
      var args;
      return this.preWork((args = arguments), (function(_this) {
        return function(callback) {
          var deployment, err, finish, finished, item, list, options, orig_stderr, orig_stdout, repo, stdout, test_file, testables, updated_file, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1;
          if (typeof args[0] === 'object' && args[0].file && _this._watched[args[0].file]) {
            updated_file = args[0].file;
          }
          finished = false;
          finish = function() {
            var i, index, inf, line, parts, result, val, warning, _i, _len, _ref;
            if (finished) {
              return;
            }
            finished = true;
            if (orig_stdout) {
              process.stdout.write = orig_stdout;
            }
            if (orig_stderr) {
              process.stderr.write = orig_stderr;
            }
            _ref = stdout || [];
            for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
              line = _ref[i];
              if ((index = line.indexOf('PhantomJS 1.9.7 (Linux): Executed ')) > -1) {
                if (result = Number(line.substr(index + 25).split(' ')[3])) {
                  _this.result(result);
                }
              } else if (line.substr(0, 6) === '    ✗ ') {
                if (warning) {
                  _this.warning(warning);
                }
                warning = {
                  file: stdout[i - 1].trim(),
                  title: line.substr(6)
                };
              } else if (line.substr(0, 1) === '\t' && line.trim() && warning) {
                if (warning.description) {
                  warning.description += '\n' + line.trim();
                } else {
                  warning.description = line.trim();
                }
              } else if (!line) {
                if (warning) {
                  _this.warning(warning);
                  warning = null;
                }
              } else if (line.substr(0, 29) === 'ERROR [preprocessor.coffee]: ') {
                inf = {
                  description: line.substr(29),
                  title: 'Compilation Error'
                };
                if (stdout[i + 1].substr(0, 5) === '  at ') {
                  parts = stdout[i + 1].substr(5).split(':');
                  line = null;
                  if (!isNaN(val = Number(parts[parts.length - 1]))) {
                    inf.line = val;
                    parts.pop();
                  }
                  inf.file = parts.join(':');
                }
                _this.error(inf);
              } else if (line.indexOf('##teamcity') > -1) {
                console.log(line);
              } else if (line) {
                console.log('[' + i + ']', line);
              }
            }
            if (warning) {
              _this.warning(warning);
            }
            return callback();
          };
          try {
            deployment = [];
            _ref = config.test.repos;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              list = item.repo;
              if (typeof list !== 'object') {
                list = [list];
              }
              for (_j = 0, _len1 = list.length; _j < _len1; _j++) {
                repo = list[_j];
                deployment.push(_this.source.repoTmp + 'clone' + _this.source.projectPath + '/' + repo);
              }
            }
            if (!(config.test.files && typeof config.test.files === 'object')) {
              config.test.files = [config.test.files];
            }
            testables = updated_file ? [updated_file] : config.test.files;
            options = {
              autoWatch: false,
              browsers: ['PhantomJS'],
              colors: false,
              files: deployment.concat(testables),
              frameworks: ['jasmine'],
              logLevel: 'WARN',
              preprocessors: {},
              reporters: ['spec'],
              singleRun: true,
              specReporter: {
                suppressPassed: true
              }
            };
            for (_k = 0, _len2 = testables.length; _k < _len2; _k++) {
              test_file = testables[_k];
              if (test_file.indexOf('.coffee') > -1) {
                options.preprocessors[test_file] = 'coffee';
              }
            }
            if (config.test.coverage) {
              options.reporters.push('coverage');
              _ref1 = config.test.repos;
              for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
                item = _ref1[_l];
                if (!(!(item.thirdParty || item.testOnly))) {
                  continue;
                }
                list = item.repo;
                if (typeof list !== 'object') {
                  list = [list];
                }
                for (_m = 0, _len4 = list.length; _m < _len4; _m++) {
                  repo = list[_m];
                  options.preprocessors[_this.source.repoTmp + 'clone' + _this.source.projectPath + '/' + repo] = 'coverage';
                }
              }
              options.coverageReporter = {
                reporters: [
                  {
                    type: 'html',
                    dir: _this.source.repoTmp + 'coverage/'
                  }, {
                    type: 'text-summary'
                  }
                ]
              };
              if (config.test.teamcity) {
                options.coverageReporter.reporters.push({
                  type: 'teamcity'
                });
              }
            }
            if (config.test.teamcity) {
              options.reporters.push('teamcity');
            }
            console.log(JSON.stringify(options, null, 2));
            orig_stdout = process.stdout.write;
            orig_stderr = process.stderr.write;
            stdout = [];
            process.stdout.write = function(out) {
              var line, _len5, _n, _ref2, _results;
              _ref2 = out.replace(/\s+$/, '').split('\n');
              _results = [];
              for (_n = 0, _len5 = _ref2.length; _n < _len5; _n++) {
                line = _ref2[_n];
                _results.push(stdout.push(line));
              }
              return _results;
            };
            process.stderr.write = function(out) {
              return _this.error(out);
            };
            karma.server.start(options, function(exit_code) {
              return finish();
            });
            if (!(config.singleRun && (updated_file == null))) {
              return _this.watch(config.test.files, function(err) {
                if (err) {
                  return _this.error(err);
                }
              });
            }
          } catch (_error) {
            err = _error;
            _this.error(err);
            return finish();
          }
        };
      })(this));
    };

    Tester.prototype.wrapError = function(inf) {
      var data, i, line_literal, lines, src, _i, _len, _ref, _ref1;
      if (!(inf && typeof inf === 'object' && (inf.title != null) && (inf.description != null))) {
        return Tester.__super__.wrapError.apply(this, arguments);
      }
      data = {
        file: inf.file ? this.source.shortFile(inf.file) : 'test',
        title: inf.title,
        description: inf.description
      };
      if (inf.line != null) {
        data.line = inf.line + 1;
      }
      if (inf.file && data.line) {
        if ((_ref = this.watched[inf.file]) != null ? _ref.data : void 0) {
          src = this.watched[inf.file].data;
        } else {
          try {
            src = fs.readFileSync(inf.file, {
              encoding: 'utf8'
            });
          } catch (_error) {}
        }
        if (src && (lines = src.split('\n')).length && lines.length >= data.line) {
          data.lines = {
            from: Math.max(1, data.line - 3),
            to: Math.min(lines.length - 1, data.line * 1 + 3)
          };
          _ref1 = lines.slice(data.lines.from - 1, +(data.lines.to - 1) + 1 || 9e9);
          for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
            line_literal = _ref1[i];
            data.lines[i + data.lines.from] = line_literal;
          }
        }
      }
      return data;
    };

    return Tester;

  })(Task);

  module.exports = Tester;

}).call(this);
