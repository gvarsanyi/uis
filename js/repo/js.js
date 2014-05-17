// Generated by CoffeeScript 1.7.1
(function() {
  var CoffeeFile, CoffeeFilesCompiler, Deployer, JsConcatenator, JsFile, JsFilesLinter, JsMinifier, JsRepo, Repo, config, messenger,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CoffeeFile = require('../file/coffee');

  CoffeeFilesCompiler = require('../task/files-compiler/coffee');

  Deployer = require('../task/deployer');

  JsConcatenator = require('../task/concatenator/js');

  JsFile = require('../file/js');

  JsFilesLinter = require('../task/files-linter/js');

  JsMinifier = require('../task/minifier/js');

  Repo = require('../repo');

  config = require('../config');

  messenger = require('../messenger');

  JsRepo = (function(_super) {
    __extends(JsRepo, _super);

    function JsRepo() {
      return JsRepo.__super__.constructor.apply(this, arguments);
    }

    JsRepo.prototype.extensions = {
      js: JsFile,
      coffee: CoffeeFile
    };

    JsRepo.prototype.getTasks = function() {
      return {
        filesCompiler: new CoffeeFilesCompiler(this),
        concatenator: new JsConcatenator(this),
        minifier: new JsMinifier(this),
        deployer: new Deployer(this),
        filesLinter: new JsFilesLinter(this)
      };
    };

    return JsRepo;

  })(Repo);

  module.exports = new JsRepo;

  messenger(module.exports);

}).call(this);
