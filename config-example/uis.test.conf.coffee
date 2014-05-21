
module.exports =
  output:    'plain'
  singleRun: true

  service: false
  css: false
  html: false
  js: false
  test:
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
    teamcity: false
