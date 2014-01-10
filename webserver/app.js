
/**
 * Module dependencies.
 */

var express = require('express'),
  redis = require("redis"),
  _ = require("underscore");

// create an error with .status. we
// can then use the property in our
// custom error handler (Connect repects this prop as well)

function error(status, msg) {
  var err = new Error(msg);
  err.status = status;
  return err;
}

// if we wanted to supply more than JSON, we could
// use something similar to the content-negotiation
// example.

// here we validate the API key,
// by mounting this middleware to /api
// meaning only paths prefixed with "/api"
// will cause this middleware to be invoked

var webserver = {};

webserver.start = function(config, appConfig) {

  // Path to our public directory
  var pub = __dirname + '/public';
  var client = redis.createClient();

  // setup middleware
  var app = express();
  app.use(app.router);
  app.use(express.static(pub));
  app.use(express.errorHandler());

  // Optional since express defaults to CWD/views
  app.set('views', __dirname + '/views');

  // Set our default template engine to "jade"
  // which prevents the need for extensions
  // (although you can still mix and match)
  app.set('view engine', 'jade');

  function User(name, email) {
    this.name = name;
    this.email = email;
  }

  // Dummy users
  var users = [
      new User('tj', 'tj@vision-media.ca')
    , new User('ciaran', 'ciaranj@gmail.com')
    , new User('aaron', 'aaron.heckmann+github@gmail.com')
  ];

  var filterDataFor = function(listName, filter, cb) {

    client.lrange(listName, 0,300, 
      function(err, results){

        var dataset = _.map(results, 
          function(item){ 
            return JSON.parse(item);
          }
        );

        dataset = _.where(dataset, filter);
        cb(dataset);
      }
    );

  }

  app.get('/', function(req, res){
    res.render('dash', { users: users });
  });

/*
reports:
  latency:
    config:
      allowJson: true
      reportName: "latency"
    filter:
      channel:"metrics"
      name:"api-latency"
*/

  app.get('/data/:reportName', function(req, res){

    var reportName = req.params["reportName"];
    var reportConfig = appConfig.reports[reportName];

    filterDataFor("winston", reportConfig.filter, 
      function(latencyData){
        res.send(latencyData);
      }
    )
  });

  app.get('/report/:reportName', function(req, res){

    var reportName = req.params["reportName"];
    var reportConfig = appConfig.reports[reportName];

    filterDataFor("winston", reportConfig.filter, 
      function(latencyData){

        res.render('dash/'+reportName, {dataset: latencyData, name: reportConfig.config.reportName});
      }
    )
  });

  app.listen(config.port);
  console.log('Express app started on port '+config.port);
}

module.exports = webserver;