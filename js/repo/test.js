// Generated by CoffeeScript 1.7.1
(function() {
  var CoffeeFile, CoffeeFilesCompiler, CoverageReporter, JsFile, Repo, TestFilesDeployer, TestRepo, Tester, config, messenger,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CoffeeFile = require('../file/coffee');

  CoffeeFilesCompiler = require('../task/files-compiler/coffee');

  CoverageReporter = require('../task/coverage-reporter');

  JsFile = require('../file/js');

  Repo = require('../repo');

  TestFilesDeployer = require('../task/files-deployer/test');

  Tester = require('../task/tester');

  config = require('../config');

  messenger = require('../messenger');

  TestRepo = (function(_super) {
    __extends(TestRepo, _super);

    TestRepo.prototype.extensions = {
      js: JsFile,
      coffee: CoffeeFile
    };

    function TestRepo() {
      config.test.repos = config.js.repos;
      TestRepo.__super__.constructor.apply(this, arguments);
    }

    TestRepo.prototype.getTasks = function() {
      return {
        filesCompiler: new CoffeeFilesCompiler(this),
        filesDeployer: new TestFilesDeployer(this),
        tester: new Tester(this),
        coverageReporter: new CoverageReporter(this)
      };
    };

    return TestRepo;

  })(Repo);

  module.exports = new TestRepo;

  messenger(module.exports);

}).call(this);
