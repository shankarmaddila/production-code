// Requires that coffeescript was installed as a module
var CoffeeScript = require('coffee-script');
CoffeeScript.register()
// Mess with args before loading the app
// process.argv = ['node.exe', 'foo', 'bar'];
 
// Include the server.coffee
var app = require('./server.coffee');