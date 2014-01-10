
// ba7f188c-523a-4a90-9d54-e6d1b70e0128
// 9672e913-7181-431c-aafd-385521e88734
var OAuth = require("oauth");

var OAuth2 = OAuth.OAuth2;    
     var twitterConsumerKey = 'ba7f188c-523a-4a90-9d54-e6d1b70e0128';
     var twitterConsumerSecret = '9672e913-7181-431c-aafd-385521e88734';
     var oauth2 = new OAuth2(twitterConsumerKey,
       twitterConsumerSecret, 
       'http://cel.ly/api', 
       'authorize',
       'oauth/token', 
       null);
     oauth2.getOAuthAccessToken(
       '',
       {'grant_type':'client_credentials'},
       function (e, access_token, refresh_token, results){
        console.log("args", arguments);
       console.log('bearer: ',access_token);
       doRequest();
     });

var doRequest = function() {

var request = require('superagent');

  require('superagent-oauth')(request);

  // once you get the access token and secret
  request.post('http://api.resource.org/users')
    .sign(OAuth, token, secret)
    .send({ my: 'data' })
    .set('X-My', 'Header')
    .end(function (res) {
      console.log(res.status, res.body);
    })


}
