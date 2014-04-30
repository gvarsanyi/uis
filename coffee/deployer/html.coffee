fs = require 'fs'

Deployer = require '../deployer'
config   = require '../config'


class HtmlDeployer extends Deployer
  deploy: (callback) =>
    delete @error
    delete @deployed

    try
      @deployed = true
    catch err
      @error = err

    callback? @error

module.exports = HtmlDeployer
