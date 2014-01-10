#!/usr/bin/env node
 
var argv = require('optimist')
  .usage('Usage: --key=[consumer key] -secret=[consumer secret]')
  .demand(['key', 'secret'])
  .argv
;
 
var baseURI = "http://cel.ly/api";

var OAuth2 = require('oauth').OAuth2;
var Step = require('step');
var colors = require('colors');
 
var REQUEST_TOKEN_URL = '/authorize';
var ACCESS_TOKEN_URL = '/token';
var OAUTH_VERSION = '2.0';
var HASH_VERSION = 'HMAC-SHA1';



function getAccessToken(oa, oauth_token, oauth_token_secret, pin) {
  oa.getOAuthAccessToken(oauth_token, oauth_token_secret, pin,
    function(error, oauth_access_token, oauth_access_token_secret, results2) {
      if (error) {
        if (parseInt(error.statusCode) == 401) {
          throw new Error('The pin number you have entered is incorrect'.bold.red);
        }
      }
      console.log('Your OAuth Access Token: '.green + (oauth_access_token).bold.cyan);
      console.log('Your OAuth Token Secret: '.green + (oauth_access_token_secret).bold.cyan);
      console.log('Now, save these two values, along with your origional consumer secret and key and use these in your twitter app'.bold.yellow);
      process.exit(1);
    });
}
 
function getRequestToken(oa) {
  
  oa.getOAuthRequestToken(function(error, oauth_token, oauth_token_secret, results){
    if(error) {
      throw new Error(([error.statusCode, error.data].join(': ')).bold.red);
    } else { 
      console.log('In your browser, log in to your twitter account.  Then visit:'.bold.green)
      console.log(('https://twitter.com/oauth/authorize?oauth_token=' + oauth_token).underline.green)
      console.log('After logged in, you will be promoted with a pin number'.bold.green)
      console.log('Enter the pin number here:'.bold.yellow);
      var stdin = process.openStdin();
      stdin.on('data', function(chunk) {
        pin = chunk.toString().trim();
        getAccessToken(oa, oauth_token, oauth_token_secret, pin);
      });
    }
  });
}
    
 
var key = argv.key.trim();
var secret = argv.secret.trim();
var oa = new OAuth2(key, secret, baseURI, "http://cel.ly/api/authorize", "http://cel.ly/api/token", null); 
console.log("oa said", oa)
//getAccessToken(oa);

var callback = function() {
  console.log("callback ", arguments);
}

 oa.getOAuthAccessToken(
   '',
   {'grant_type':'client_credentials'},
   function (e, access_token, refresh_token, results){
     console.log('bearer: ',access_token);
     oa.get('protected url', 
       access_token, function(e,data,res) {
         if (e) return callback(e, null);
         if (res.statusCode!=200) 
           return callback(new Error(
             'OAuth2 request failed: '+
             res.statusCode),null);
         try {
           data = JSON.parse(data);        
         }
         catch (e){
           return callback(e, null);
         }
         return callback(e, data);
      });
   });

