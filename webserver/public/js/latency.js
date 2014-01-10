// (It's CSV, but GitHub Pages only gzip's JSON at the moment.)
//d3.csv("/data/latency", function(error, flights) {

var formatPercent = d3.format(".1%");

var margin = {top: 10, right: 30, bottom: 30, left: 30},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var x = d3.scale.linear()
    .domain([0, 1000])
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var svg = d3.select("body").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

d3.json("/data/latency", type, function(error, histogram) {
  var n = d3.sum(histogram, function(d) { return d.y = d.a + d.b; });

  y.domain([0, d3.max(histogram, function(d) { return d.y; })]);

  var bar = svg.insert("g", ".axis")
      .attr("class", "bar")
    .selectAll("g")
      .data(histogram)
    .enter().append("g")
      .attr("transform", function(d) { return "translate(" + x(d.x) + ",0)"; });

  bar.append("rect")
      .attr("class", "b")
      .attr("x", 1)
      .attr("y", function(d) { return y(d.a); })
      .attr("width", x(histogram[0].dx) - 1)
      .attr("height", function(d) { return height - y(d.a); });

  /*
  bar.append("rect")
      .attr("class", "a")
      .attr("x", 1)
      .attr("y", function(d) { return y(d.y); })
      .attr("width", x(histogram[0].dx) - 1)
      .attr("height", function(d) { return height - y(d.a); });
  */

  bar.filter(function(d) { return d.y / n >= .0095; }).append("text")
      .attr("dy", ".35em")
      .attr("transform", function(d) { return "translate(" + x(histogram[0].dx) / 2 + "," + (y(d.y) + 6) + ")rotate(-90)"; })
      .text(function(d) { return formatPercent(d.y / n); });
});

function type(d) {
  d.x = +(+moment(d.timestamp));
  d.dx = +d.dx;
  d.a = +d.value;
  d.b = +d.b;
  return d;
}