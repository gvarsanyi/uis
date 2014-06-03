#!/usr/bin/env node

function start() {
  require('coffee-script/register');
  require('./coffee/app');
}

var child_process = require('child_process'),
    fs            = require('fs');

try {
  require(__dirname + '/node_modules/node-sass');
  start();
} catch (err) {
  var homedir_key = (process.platform == 'win32') ? 'USERPROFILE' : 'HOME',
      sass_path   = process.env[homedir_key] + '/.uis/node-sass';

  try {
    require(sass_path);
    start();
  } catch (err) {
    proc = child_process.exec(__dirname + '/build-node-sass.sh ' + sass_path,
                              {silent: true},
                              function (err, stdout, stderr) {
      if (err) {
        console.error('Installation failed');
        process.exit(1);
      } else {
        start();
      }
    });
    proc.stderr.on('data', function (data) {
      process.stderr.write(data);
    });
    proc.stdout.on('data', function (data) {
      process.stdout.write(data);
    });
  }
}
