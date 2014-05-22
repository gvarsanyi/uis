// Generated by CoffeeScript 1.7.1
(function() {
  var CoverageReporter, Task, config, fs, glob, karma,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  glob = require('glob');

  karma = require('karma');

  Task = require('../task');

  config = require('../config');

  CoverageReporter = (function(_super) {
    var double_dec;

    __extends(CoverageReporter, _super);

    double_dec = function(n) {
      var parts;
      n = String(n);
      if (n.indexOf('.') === -1) {
        n += '.00';
      } else {
        parts = n.split('.');
        while (parts[1].length < 2) {
          parts[1] += '0';
        }
        parts[1] = parts[1].substr(0, 2);
        n = parts.join('.');
      }
      return n;
    };

    CoverageReporter.prototype.name = 'coverageReporter';

    function CoverageReporter() {
      this.wrapError = __bind(this.wrapError, this);
      this.work = __bind(this.work, this);
      this.size = __bind(this.size, this);
      this.condition = __bind(this.condition, this);
      CoverageReporter.__super__.constructor.apply(this, arguments);
      if (config.test.coverage) {
        if (typeof config.test.coverage !== 'object') {
          config.test.coverage = {
            bar: 80
          };
        } else if (isNaN(Number(String(config.test.coverage.bar)))) {
          config.test.coverage.bar = 80;
        } else {
          config.test.coverage.bar = Math.min(100, config.test.coverage.bar);
          config.test.coverage.bar = Math.max(0, config.test.coverage.bar);
          if (config.test.coverage.bar === 0) {
            config.test.coverage = false;
          }
        }
      }
    }

    CoverageReporter.prototype.condition = function() {
      var _ref;
      return config.test.coverage && !!config[this.source.name].files && this.source.tasks.filesLoader.count() && !((_ref = this.source.tasks.tester.warning()) != null ? _ref.length : void 0);
    };

    CoverageReporter.prototype.size = function() {
      return this._result || {};
    };

    CoverageReporter.prototype.work = function() {
      var args;
      return this.preWork((args = arguments), (function(_this) {
        return function(callback) {
          var dir, err, finish, finished, item, list, options, repo, test_file, tester, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
          finished = false;
          finish = function() {
            if (finished) {
              return;
            }
            finished = true;
            return glob(_this.source.repoTmp + 'coverage/text/**/coverage.txt', function(err, files) {
              if (err) {
                _this.error(err);
                return callback();
              } else if (!files.length) {
                _this.error('coverage output file generation failed');
                return callback();
              } else if (files.length > 1) {
                _this.error('coverage output file generation ambiguity');
                return callback();
              } else {
                return fs.readFile(files[0], {
                  encoding: 'utf8'
                }, function(err, data) {
                  var branches, cols, desc, dir, file, functions, info, item, line, lines, lowest, parts, report, rows, statements, _i, _j, _len, _len1, _ref, _ref1, _ref2;
                  if (err) {
                    _this.error(err);
                    return callback();
                  } else {
                    report = {
                      files: {},
                      dirs: {}
                    };
                    lowest = [];
                    dir = null;
                    _ref = data.split('\n');
                    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                      line = _ref[_i];
                      if (!(line.substr(0, 4) !== 'File' && line[0] !== '-')) {
                        continue;
                      }
                      parts = line.split(' | ');
                      _ref1 = (function() {
                        var _j, _len1, _ref1, _results;
                        _ref1 = parts.slice(1, 5);
                        _results = [];
                        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                          item = _ref1[_j];
                          _results.push(Number(item.replace('|', '').trim()));
                        }
                        return _results;
                      })(), statements = _ref1[0], branches = _ref1[1], functions = _ref1[2], lines = _ref1[3];
                      info = {
                        statements: statements,
                        branches: branches,
                        functions: functions,
                        lines: lines
                      };
                      if (line.substr(0, 6) === '      ') {
                        file = dir + parts[0].trim();
                        report.files[file] = info;
                        if (statements < config.test.coverage.bar) {
                          lowest.push({
                            file: file,
                            statements: statements
                          });
                        }
                      } else if (line.substr(0, 3) === '   ') {
                        dir = parts[0].trim();
                        report.dirs[dir] = info;
                      } else if (line.substr(0, 9) === 'All files') {
                        report.all = info;
                      }
                    }
                    if (lowest.length) {
                      lowest.sort(function(a, b) {
                        if (a.statements > b.statements) {
                          return 1;
                        }
                        return -1;
                      });
                      rows = [];
                      for (_j = 0, _len1 = lowest.length; _j < _len1; _j++) {
                        item = lowest[_j];
                        rows.push([item.file, double_dec(item.statements) + '%']);
                      }
                      desc = lowest.length + ' file' + (lowest.length > 1 ? 's' : '') + ' do' + (lowest.length > 1 ? '' : 'es') + ' not meet the bar.';
                      cols = [
                        {
                          title: 'Files not meeting the bar'
                        }, {
                          align: 'right'
                        }
                      ];
                      if (((_ref2 = report.all) != null ? _ref2.statements : void 0) && report.all.statements < config.test.coverage.bar) {
                        _this.warning({
                          title: 'Low test coverage',
                          description: report.all.statements + '% of all statements' + ' covered. ' + desc,
                          table: {
                            data: rows,
                            columns: cols
                          }
                        });
                      } else {
                        _this.warning({
                          description: report.all.statements + '% of statements ' + ' covered overall, but ' + desc,
                          table: {
                            data: rows,
                            columns: cols
                          }
                        });
                      }
                    }
                    _this.result(report);
                    return callback();
                  }
                });
              }
            });
          };
          try {
            tester = _this.source.tasks.tester;
            options = tester.getDefaultOptions('dot', tester.getCloneDeployment(), config.test.files);
            _ref = config.test.files;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              test_file = _ref[_i];
              if (test_file.indexOf('.coffee') > -1) {
                options.preprocessors[test_file] = 'coffee';
              }
            }
            if (config.test.coverage) {
              options.reporters.push('coverage');
              _ref1 = config.test.repos;
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                item = _ref1[_j];
                if (!(!(item.thirdParty || item.testOnly))) {
                  continue;
                }
                list = item.repo;
                if (typeof list !== 'object') {
                  list = [list];
                }
                dir = _this.source.repoTmp + 'clone' + _this.source.projectPath + '/';
                for (_k = 0, _len2 = list.length; _k < _len2; _k++) {
                  repo = list[_k];
                  options.preprocessors[dir + repo] = 'coverage';
                }
              }
              dir = _this.source.repoTmp + 'coverage/';
              options.coverageReporter = {
                instrumenter: {
                  '**/*.coffee': 'istanbul'
                },
                reporters: [
                  {
                    type: 'html',
                    dir: dir + 'html/'
                  }, {
                    type: 'text',
                    dir: dir + 'text/',
                    file: 'coverage.txt'
                  }
                ]
              };
              if (config.test.teamcity) {
                options.coverageReporter.reporters.push({
                  type: 'teamcity'
                });
              }
            }
            return karma.server.start(options, function(exit_code) {
              if (exit_code > 0) {
                _this.error('Karma coverage failed, exit code: ' + exit_code);
              }
              return finish();
            });
          } catch (_error) {
            err = _error;
            _this.error(err);
            return finish();
          }
        };
      })(this));
    };

    CoverageReporter.prototype.wrapError = function(inf) {
      if (!(inf && typeof inf === 'object' && (inf.title != null) && (inf.description != null))) {
        return CoverageReporter.__super__.wrapError.apply(this, arguments);
      }
      return inf;
    };

    return CoverageReporter;

  })(Task);

  module.exports = CoverageReporter;

}).call(this);
