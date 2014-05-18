// Generated by CoffeeScript 1.7.1
(function() {
  var Task, Tester, config, fs, karma,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  karma = require('karma');

  Task = require('../task');

  config = require('../config');

  Tester = (function(_super) {
    __extends(Tester, _super);

    function Tester() {
      this.work = __bind(this.work, this);
      this.size = __bind(this.size, this);
      this.getDefaultOptions = __bind(this.getDefaultOptions, this);
      this.getCloneDeployment = __bind(this.getCloneDeployment, this);
      this.followUp = __bind(this.followUp, this);
      this.condition = __bind(this.condition, this);
      return Tester.__super__.constructor.apply(this, arguments);
    }

    Tester.prototype.name = 'tester';

    Tester.prototype.condition = function() {
      var _ref;
      return !!config[this.source.name].files && ((_ref = this.source.tasks.filesLoader) != null ? _ref.count() : void 0);
    };

    Tester.prototype.followUp = function(node) {
      var _ref;
      return (_ref = this.source.tasks.coverageReporter) != null ? _ref.work(node) : void 0;
    };

    Tester.prototype.getCloneDeployment = function() {
      var deployment, item, list, repo, _i, _j, _len, _len1, _ref;
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
          deployment.push(this.source.repoTmp + 'clone' + this.source.projectPath + '/' + repo);
        }
      }
      return deployment;
    };

    Tester.prototype.getDefaultOptions = function(reporter, deployment, test_files) {
      return {
        autoWatch: false,
        browsers: ['PhantomJS'],
        colors: false,
        files: deployment.concat(test_files),
        frameworks: ['jasmine'],
        logLevel: 'ERROR',
        preprocessors: {},
        reporters: [reporter],
        singleRun: true
      };
    };

    Tester.prototype.size = function() {
      return this._result || 0;
    };

    Tester.prototype.work = function() {
      var args;
      return this.preWork((args = arguments), (function(_this) {
        return function(callback) {
          var err, finish, finished, options, orig_stderr, orig_stdout, stdout, test_file, testables, updated_file, _i, _len;
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
                console.log('karma output [' + i + ']', line);
              }
            }
            if (warning) {
              _this.warning(warning);
            }
            return callback();
          };
          try {
            if (!(config.test.files && typeof config.test.files === 'object')) {
              config.test.files = [config.test.files];
            }
            testables = updated_file ? [updated_file] : config.test.files;
            options = _this.getDefaultOptions('spec', _this.getCloneDeployment(), config.test.files);
            options.specReporter = {
              suppressPassed: true
            };
            for (_i = 0, _len = testables.length; _i < _len; _i++) {
              test_file = testables[_i];
              if (test_file.indexOf('.coffee') > -1) {
                options.preprocessors[test_file] = 'coffee';
              }
            }
            if (config.test.teamcity && !updated_file) {
              options.reporters.push('teamcity');
            }
            orig_stdout = process.stdout.write;
            orig_stderr = process.stderr.write;
            stdout = [];
            process.stdout.write = function(out) {
              var line, _j, _len1, _ref, _results;
              _ref = out.replace(/\s+$/, '').split('\n');
              _results = [];
              for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                line = _ref[_j];
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
