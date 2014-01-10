var express = require('express'),
    app = express(),
    _ = require("underscore");

var myServerAddress = "localhost";
var myServerPort = 3000;

var ConsumerKey = 'ba7f188c-523a-4a90-9d54-e6d1b70e0128';
var ConsumerSecret = '9672e913-7181-431c-aafd-385521e88734';

var manualToken = "2b6f02e6d48e58bbc2170ee283602e5570446bb63c2aa2efbb0eb946693e53db37929953d2a330ed";

var baseURI = "http://cel.ly/api";

var patchUnderscore = function(us) {
  us["isError"] = function(testObj) {
    return (testObj instanceof Error);
  }
  return us;
}

_ = patchUnderscore(_);

var OAuth2 = require('simple-oauth2')({
  clientID: ConsumerKey,
  clientSecret: ConsumerSecret,
  site: baseURI,
  tokenPath: '/token',
  authorizationPath: '/authorize'
});

//http://cel.ly/api/oauth/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fcallback&scope=notifications&state=3(%230%2F!~&response_type=code&client_id=ba7f188c-523a-4a90-9d54-e6d1b70e0128

// Authorization uri definition
var authorization_uri = OAuth2.AuthCode.authorizeURL({
  redirect_uri: 'http://'+myServerAddress+':'+myServerPort+'/callback',
  scope: '',
  state: ''
});

// Initial page redirecting to Github
app.get('/auth', function (req, res) {
    res.redirect(authorization_uri);
});

// Callback service parsing the authorization token and asking for the access token
app.get('/callback', function (req, res) {
  var code = req.query.code; 
  console.log('/callback', req);
  OAuth2.AuthCode.getToken({
    code: code,
    redirect_uri: 'http://'+myServerAddress+':'+myServerPort+'/callback'
  }, saveToken);

  function saveToken(error, result) {
    console.log("save token", arguments);
    if (error) { console.log('Access Token Error', error.message); }
    token = OAuth2.AccessToken.create(result);
    console.log("Have token ",token);
  }
});

app.get('/echo', function (req, res) {
  res.send('Hello World');
});

var fetchUserInfo = function(done) {

  var request = require('superagent');
  var url = baseURI+'/me'+"?oauth_token="+manualToken+111;

  request
    .get(url)
    .set('Content-Type', 'application/json')
    .end(
      function(err, res){
        if (err || _.has(res.body,"error")) {
          if (_.has(res.body,"error")) {
            err = new Error(res.body.error);
          }
          done(err);
        } else {
          console.log(arguments);
          done(res.body.response);        
        }
      }
    )
}

app.get('/', 
  function(req, res){
    fetchUserInfo(
      function(body){
        console.log(arguments);

        if (_.isError(body)) {
          res.send("It appears you don't have a valid token..")
        } else {
          res.send("Welcome back ",body.userName);
        }

      }
    );
  }
)

app.get('/test', 
  function(req, res){

  }
)


app.listen(3000);

console.log('Express server started on port 3000');


//Example: T=DOWN-0395