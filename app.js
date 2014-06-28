#!/usr/bin/env node

// Check for updates, pull in coffee-script and continue with app.coffee //

var notifier = require('update-notifier')();
if (notifier.update) {
  notifier.notify();
}

require('coffee-script/register');
require('./coffee/app');
