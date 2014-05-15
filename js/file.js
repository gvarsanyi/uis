// Generated by CoffeeScript 1.7.1
(function() {
  var File, path;

  path = require('path');

  File = (function() {
    function File(repo, path, options) {
      this.repo = repo;
      this.path = path;
      this.options = options;
    }

    File.prototype.shortPath = function() {
      var project_path;
      if (!this._shortPath) {
        this._shortPath = this.path;
        project_path = path.resolve(process.cwd());
        if (this._shortPath.substr(0, project_path.length) === project_path) {
          this._shortPath = this._shortPath.substr(project_path.length + 1);
        }
      }
      return this._shortPath;
    };

    return File;

  })();

  module.exports = File;

}).call(this);
