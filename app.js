#!/usr/bin/env node

if (!require('fs').existsSync(__dirname + '/node_modules/node-sass')) {
  console.error('uis node-sass installation required. Run:\nsudo uis-install-node-sass');
  process.exit(1);
}

require('coffee-script/register');
require('./coffee/app');
