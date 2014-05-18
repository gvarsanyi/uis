// Generated by CoffeeScript 1.7.1
(function() {
  var FilesLoader, Repo, config, gaze, glob, md5, messenger, mkdirp, path, rimraf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  path = require('path');

  gaze = require('gaze');

  glob = require('glob');

  md5 = require('MD5');

  mkdirp = require('mkdirp');

  rimraf = require('rimraf');

  FilesLoader = require('./task/files-loader');

  config = require('./config');

  messenger = require('./messenger');

  Repo = (function() {
    function Repo() {
      this.setTmp = __bind(this.setTmp, this);
      this.shortFile = __bind(this.shortFile, this);
      this.load = __bind(this.load, this);
      this.fileUpdate = __bind(this.fileUpdate, this);
      this.checkAllTasksFinished = __bind(this.checkAllTasksFinished, this);
      var i, item, name, task, _i, _len, _ref, _ref1, _ref2;
      this.pathes = [];
      this.sources = {};
      this.name = this.constructor.name.replace('Repo', '').toLowerCase();
      this.projectPath = path.resolve(process.cwd());
      this.setTmp();
      this.dirs = (_ref = config[this.name]) != null ? _ref.repos : void 0;
      if (!(this.dirs instanceof Array)) {
        this.dirs = [this.dirs];
      }
      _ref1 = this.dirs;
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        item = _ref1[i];
        if (typeof item !== 'object') {
          this.dirs[i] = {
            repo: item
          };
        }
      }
      this.tasks = {
        filesLoader: new FilesLoader(this)
      };
      _ref2 = (typeof this.getTasks === "function" ? this.getTasks() : void 0) || {};
      for (name in _ref2) {
        task = _ref2[name];
        this.tasks[name] = task;
      }
      this.load();
    }

    Repo.prototype.checkAllTasksFinished = function() {
      var name, task, _ref;
      if (config.singleRun) {
        _ref = this.tasks;
        for (name in _ref) {
          task = _ref[name];
          if (!task.done()) {
            return;
          }
        }
        return setTimeout(function() {
          return process.exit(0);
        }, 10);
      }
    };

    Repo.prototype.fileUpdate = function(event, file, force_reload) {
      var node;
      if (node = this.sources[file]) {
        return this.tasks.filesLoader.workFile(node, (function(_this) {
          return function(changed) {
            var _base;
            if ((changed || force_reload) && !_this.tasks.filesLoader.error()) {
              if (!node.data) {
                return messenger.note('emptied: ' + _this.shortFile(file));
              } else {
                messenger.note('updating: ' + _this.shortFile(file));
                if (typeof (_base = _this.tasks.filesLoader).followUp === "function") {
                  _base.followUp(node);
                }
                return _this.checkAllTasksFinished();
              }
            }
          };
        })(this));
      } else {
        return messenger.note('deleted: ' + this.shortFile(file));
      }
    };

    Repo.prototype.load = function() {
      var file, files, inst, instanciate_file, k, opt, options, pattern, repo, v, watch, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4;
      instanciate_file = (function(_this) {
        return function(file, _options) {
          var class_ref, ext, k, options, v, _ref;
          ext = file.substr(file.lastIndexOf('.') + 1);
          if (class_ref = _this.extensions[ext]) {
            options = {};
            _ref = _options || {};
            for (k in _ref) {
              v = _ref[k];
              options[k] = v;
            }
            return new class_ref(_this, file, options);
          }
        };
      })(this);
      _ref = config[this.name].repos;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        repo = _ref[_i];
        options = {};
        _ref1 = ['testOnly', 'thirdParty'];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          opt = _ref1[_j];
          if (repo[opt] != null) {
            options[opt] = repo[opt];
          }
        }
        _ref2 = ['basedir', 'deploy'];
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          opt = _ref2[_k];
          if (repo[opt]) {
            options[opt] = path.resolve(repo[opt]);
          } else if (config[this.name][opt]) {
            options[opt] = path.resolve(config[this.name][opt]);
          }
        }
        _ref3 = ['minify', 'rubysass'];
        for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
          opt = _ref3[_l];
          if (repo[opt]) {
            options[opt] = repo[opt];
          } else if (config[this.name][opt]) {
            options[opt] = config[this.name][opt];
          }
        }
        if (typeof repo.repo !== 'object') {
          repo.repo = [repo.repo];
        }
        _ref4 = repo.repo;
        for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
          pattern = _ref4[_m];
          if (pattern[0] !== '/') {
            pattern = this.projectPath + '/' + pattern;
          }
          files = glob.sync(pattern);
          for (_n = 0, _len5 = files.length; _n < _len5; _n++) {
            file = files[_n];
            if (this.sources[file]) {
              for (k in options) {
                v = options[k];
                this.sources[file].options[k] = v;
              }
            } else if (!this.sources[file] && (inst = instanciate_file(file, options))) {
              this.sources[file] = inst;
              this.pathes.push(file);
            }
          }
        }
        if (!config.singleRun) {
          watch = new gaze;
          watch.on('all', this.fileUpdate);
          watch.add(repo.repo);
        }
      }
      return setTimeout((function(_this) {
        return function() {
          return _this.tasks.filesLoader.work();
        };
      })(this));
    };

    Repo.prototype.shortFile = function(file_path) {
      if (file_path.substr(0, this.projectPath.length) === this.projectPath) {
        return file_path.substr(this.projectPath.length + 1);
      }
      return file_path;
    };

    Repo.prototype.setTmp = function() {
      var err;
      this.tmp = this.projectPath + '/.uis/';
      this.repoTmp = this.tmp + this.name + '/';
      try {
        return rimraf.sync(this.repoTmp);
      } catch (_error) {
        err = _error;
        console.error('[ERROR] Could not clear' + this.repoTmp);
        return process.exit(1);
      }
    };

    return Repo;

  })();

  module.exports = Repo;

}).call(this);
