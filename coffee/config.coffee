
# config = require(process.cwd() + '/package.json')?.uis
config = require('../config.json').uis['default']

module.exports[k] = v for k, v of config or {}
