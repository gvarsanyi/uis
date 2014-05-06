
try
  config = require(process.cwd() + '/package.json')?.config

(config ?= {}).repo =
  css:  ['sass/**/core.scss']
  html: ['jade/*.jade', 'jade/partials/**/*.jade']
  js:   ['third-party/js/moment.js', 'third-party/js/moment-timezone.js',
         'third-party/js/moment-timezone-data.js', 'third-party/js/angular.js',
         'third-party/js/**/*.js', 'coffee/**/*.coffee']

config.deploy =
  css:  '.deploy/site.css'
  html: '.deploy/'
  js:   '.deploy/site.js'

module.exports[k] = v for k, v of config or {}
