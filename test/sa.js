  var request = require('superagent');
  var url = 'https://gist.github.com/visionmedia/9fff5b23c1bf1791c349/raw/3e588e0c4f762f15538cdaf9882df06b3f5b3db6/works.js';

  request.get(url)
  	.end(function(err, res){
    if (err) throw err;
    console.log(arguments);
  })