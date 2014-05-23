
module.exports =
  output:    'fancy'
  singleRun: false

  service:
    contentsDir: 'static'
    hud:         false
    log:         false
    interface:   ''
    port:        9080
    proxy:
      pattern: '/dashboard-calendar-ui/api/*'
      target:  'http://localhost:9999'

  css:
    deploy:   'static/site.css'
    minify:   true
    rubysass: true
    repos:
      repo: 'sass/**/core.scss'

  html:
    repos:
      basedir: 'jade'
      deploy:  'static'
      minify:  true
      repo:    ['jade/*.jade', 'jade/partials/**/*.jade']

  js:
    deploy: 'static/site.js'
    minify: true
    repos: [
      {
        repo: [ 'third-party/js/moment.js'
                'third-party/js/moment-timezone.js'
                'third-party/js/moment-timezone-data.js'
                'third-party/js/angular.js'
                'third-party/js/**/*.js' ]
        thirdParty: true
      }, {
        repo:     'third-party/js/test/**/*.js'
        testOnly: true
      }, {
        repo: 'coffee/**/*.coffee'
      }
    ]

  test:
    coverage:
      bar: 80
    files: 'test/**/*.coffee'
    teamcity: false
