
function random(name) {
  var value = 0,
      values = [],
      i = 0,
      last;
  return context.metric(function(start, stop, step, callback) {
    start = +start, stop = +stop;
    if (isNaN(last)) last = start;
    while (last < stop) {
      last += step;
      value = Math.max(-10, Math.min(10, value + .8 * Math.random() - .4 + .2 * Math.cos(i += .2)));
      values.push(value);
    }
    callback(null, values = values.slice((start - stop) / step));
  }, name);
}

var context = cubism.context()
    .serverDelay(0)
    .clientDelay(0)
    .step(1e3)
    .size(960);

var foo = random("foo"),
    bar = random("bar");

d3.json("/data/latency", function(error, foo) {

  d3.select("#example2a").call(function(div) {
    div.datum(foo);

    div.append("div")
        .attr("class", "horizon")
        .call(context.horizon()
          .height(foo.value)
          .mode("mirror")
          .colors(["#bdd7e7","#bae4b3"])
          .title("Area (120px)")
          .extent([-10, 10]));

    div.append("div")
        .attr("class", "horizon")
        .call(context.horizon()
          .height(30)
          .mode("mirror")
          .colors(["#bdd7e7","#bae4b3"])
          .title("Area (30px)")
          .extent([-10, 10]));
  });

  // On mousemove, reposition the chart values to match the rule.
  context.on("focus", function(i) {
    d3.selectAll(".value").style("right", i == null ? null : context.size() - i + "px");
  });

});


