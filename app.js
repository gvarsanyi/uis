#!/usr/bin/env node


require('coffee-script/register');
require('./coffee/app');


// remove legacy node-sass installation
var child_process = require('child_process'),
    fs            = require('fs'),
    homedir_key   = (process.platform == 'win32') ? 'USERPROFILE' : 'HOME',
    sass_path     = process.env[homedir_key] + '/.uis';

fs.exists(sass_path, function (exists) {
  if (exists) {
    console.log('removing ' + sass_path);
    child_process.exec('rm -rf ' + sass_path, function (err, stdout, stderr) {
      if (err) {
        console.error('removal exit status:', err);
        console.log(stdout);
        console.error(stderr);
      }
    });
  }
});
