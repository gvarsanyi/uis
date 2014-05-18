// Generated by CoffeeScript 1.7.1
(function() {
  var FilesCompiler, SassFilesCompiler, child_process, config, fs, messenger, path, sass,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  child_process = require('child_process');

  fs = require('fs');

  path = require('path');

  sass = require('node-sass');

  FilesCompiler = require('../files-compiler');

  config = require('../../config');

  messenger = require('../../messenger');

  SassFilesCompiler = (function(_super) {
    __extends(SassFilesCompiler, _super);

    function SassFilesCompiler() {
      this.wrapError = __bind(this.wrapError, this);
      this.workFile = __bind(this.workFile, this);
      return SassFilesCompiler.__super__.constructor.apply(this, arguments);
    }

    SassFilesCompiler.prototype.workFile = function() {
      return this.preWorkFile(arguments, (function(_this) {
        return function(source, callback) {
          var cmd, compilers, err, finish, node_sass_error, node_sass_success, stats;
          stats = {};
          compilers = 0;
          finish = function(err) {
            compilers += 1;
            if (err) {
              _this.error(err, source);
            }
            if (compilers === 2 || !source.options.rubysass) {
              if (config.singleRun) {
                return callback();
              } else {
                return _this.watch(stats.includedFiles, source, function(err) {
                  if (err) {
                    _this.error(err, source);
                  }
                  return callback();
                });
              }
            }
          };
          try {
            if (source.data == null) {
              throw new Error('[SassFilesCompiler] Missing source: ' + source.path);
            }
            if (source.options.rubysass) {
              cmd = 'sass --cache-location=' + _this.source.repoTmp + '../.sass-cache -q ' + source.path;
              child_process.exec(cmd, {
                maxBuffer: 128 * 1024 * 1024
              }, function(err, stdout, stderr) {
                if (!err) {
                  source[_this.sourceProperty] = stdout;
                }
                return finish(err);
              });
            }
          } catch (_error) {
            err = _error;
            _this.error(err, source);
            callback();
          }
          try {
            if (config.singleRun && source.options.rubysass) {
              return finish();
            }
            node_sass_error = function(err) {
              var check_variations, checks, dir, file, name, _ref;
              if (!((_ref = stats.includedFiles) != null ? _ref.length : void 0)) {
                file = String(err).split(':')[0];
                name = file.split('/').pop();
                dir = file.substr(0, file.length - name.length);
                checks = [file + '.scss', dir + '_' + name + '.scss', file + '.sass', dir + '_' + name + '.sass', file, dir + '_' + name];
                check_variations = function() {
                  if (!checks.length) {
                    return finish();
                  }
                  return fs.exists((file = checks.shift()), function(exists) {
                    if (exists) {
                      stats.includedFiles = [file];
                      return finish();
                    }
                    return check_variations();
                  });
                };
                return check_variations();
              }
            };
            node_sass_success = function(data) {
              if (!source.options.rubysass) {
                source[_this.sourceProperty] = data;
              }
              return finish();
            };
            return sass.render({
              data: source.data,
              error: node_sass_error,
              includePaths: [path.dirname(source.path) + '/'],
              stats: stats,
              success: node_sass_success
            });
          } catch (_error) {
            err = _error;
            return finish(err);
          }
        };
      })(this));
    };

    SassFilesCompiler.prototype.wrapError = function(inf, source) {
      var data, desc, i, line, line_literal, lines, long_file, parts, src, val, _i, _len, _ref, _ref1, _ref2;
      data = SassFilesCompiler.__super__.wrapError.apply(this, arguments);
      inf = String(inf);
      lines = (function() {
        var _i, _len, _ref, _results;
        _ref = inf.split('\n');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          line = _ref[_i];
          _results.push(line.trim());
        }
        return _results;
      })();
      if ((parts = lines[0].split(': '))[0] === 'Error' && (desc = parts.slice(3).join(': ')).length > 20) {
        data.title = parts[1] + ': ' + parts[2];
        data.description = desc;
        if ((parts = (_ref = lines[1]) != null ? _ref.split(' ') : void 0)[4] && parts[0] === 'on' && parts[1] === 'line' && parts[3] === 'of') {
          long_file = parts.slice(4).join(' ');
          data.file = this.source.shortFile(long_file);
          if ((val = Number(parts[2])) > 1 || val === 0 || val === 1) {
            data.line = val;
          }
          if (data.file && data.line) {
            if (source.path === long_file) {
              src = source.data;
            } else if ((_ref1 = this._watched[long_file]) != null ? _ref1.data : void 0) {
              src = this._watched[long_file].data;
            } else {
              try {
                src = fs.readFileSync(long_file, {
                  encoding: 'utf8'
                });
              } catch (_error) {}
            }
            if (src && (lines = src.split('\n')).length && lines.length >= data.line) {
              data.lines = {
                from: Math.max(1, data.line - 3),
                to: Math.min(lines.length - 1, data.line * 1 + 3)
              };
              _ref2 = lines.slice(data.lines.from - 1, +(data.lines.to - 1) + 1 || 9e9);
              for (i = _i = 0, _len = _ref2.length; _i < _len; i = ++_i) {
                line_literal = _ref2[i];
                data.lines[i + data.lines.from] = line_literal;
              }
            }
          }
        }
      }
      return data;
    };

    return SassFilesCompiler;

  })(FilesCompiler);

  module.exports = SassFilesCompiler;

}).call(this);
