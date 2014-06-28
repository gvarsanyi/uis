
console.log """

 UIS quick help
==============================================================================

 Common directives
-------------------

  uis compile [watch]
    Generates statics based on configuration (check uis config files)

  uis dev
    Generates statics based on configuration and keeps watching
    Fires up web service with head-up display
    Runs tests

  uis test [watch]
    Runs tests with karma

  uis version
    Prints current UIS version


 Common options
----------------

  --single-run[=false|true]   watch mode on/off
  --test.log[=false|true]     full karma log on/off
  --full-log[=false|true]     full logging of warning & error messages on/off
  --service.log[=false|true]  service call logs on/off

"""

process.exit 0
