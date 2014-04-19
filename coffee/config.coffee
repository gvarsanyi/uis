
try
  config = require(process.cwd() + '/package.json')?.config

config.repo =
  css:  ['sass/**/core.scss']
  html: ['jade/*.jade', 'jade/partials/**/*.jade']
  js:   ['third-party/js/**/*.js', 'coffee/**/*.coffee']

config.deploy =
  css:  'static/site.css'
  html: 'static/'
  js:   'static/site.js'

module.exports[k] = v for k, v of config or {}
