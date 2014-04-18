
try
  config = require(process.cwd() + '/package.json')?.config
  module.exports[k] = v for k, v of config or {}

module.exports.repos =
  css:  ['sass/**/core.scss']
  html: ['jade/*.jade', 'jade/partials/**/*.jade']
  js:   ['third-party/js/**/*.js', 'coffee/**/*.coffee']
