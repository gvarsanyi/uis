dynmod = require 'dynmod'


class Dependencies
  cssminify: -> dynmod 'clean-css@2.1.8'
  coffee:    -> dynmod 'coffee-script@1.7.1'
  gaze:      -> dynmod 'gaze@0.6.3'
  jade:      -> dynmod 'jade@1.3.1'
  jsminify:  -> dynmod 'uglify-js@2.4.13'
  sass:      -> dynmod 'node-sass@0.8.4'


module.exports = Dependencies
