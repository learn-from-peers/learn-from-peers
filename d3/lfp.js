
// DATA

var raw =
    [
        ["Valentin", 10, 15, "D3",             "PL",       3],
        ["Tristan",  10, 29, "Julia",          "SysNet",   3],
        ["Wilson",   11, 05, "Dev tools",      "SysNet",   3],
        ["Anup",     11, 12, "git",            "MS",      -1],
        ["Karyn",    11, 19, "tcpdump",        "SysNet",   4],
        ["Stephen",  11, 26, "Kickstarter",    "SoftEng",  3],
        ["Kian",     12, 03, "Postgres",       "DB",       3],
        ["Marc",     12, 10, "FP programming", "PL",       3],
    ]
;

var lfpData = _(raw)
    .map(function(l) {
        var i = 0;
        return {
            "name" : l[i++],
            "date" : mkDate(2014, l[i++], l[i++]),
            "topic": l[i++],
            "group": l[i++],
            "floor": l[i++],
        };
    })
    .value();
;

// CONFIGURATION

var firstDay = mkDate(2014, 9, 1);   // September 1st 2014
var lastDay  = mkDate(2014, 12, 31); // December 31st 2014
var displayedMonth = 10; // initially October
var calendarWidth = 800;
var calendarHeight = 600;
var ringDiameter = 400;

// GLOBALS

var day    = function(x) { return +d3.time.format("%w")(x); } // 0 - 6
var week   = function(x) { return +d3.time.format("%U")(x); } // 0 - 51
var month  = function(x) { return +d3.time.format("%m")(x); } // 1 - 12
var format = d3.time.format("%b %e"); // Jan 1 - Dec 31
function mkDate(y, m, d) { return new Date(y, m - 1, d); }
var outerRadius = ringDiameter / 2;
var innerRadius = ringDiameter / 3;
var arc = d3.svg.arc()
    .innerRadius(innerRadius)
    .outerRadius(outerRadius)
;
var color = d3.scale.category10();

var ring, calendarGroup, wCell, hCell;

$(document).ready(function() {

    calendar =
        d3.select("body")
        .append("svg")
        .attr("width", calendarWidth)
        .attr("height", calendarHeight)
    ;

    ring =
        d3.select("body")
        .append("svg")
        .attr("width", ringDiameter)
        .attr("height", ringDiameter)
    ;

    calendarGroup = calendar.append("g");

    wCell = calendarWidth / 6;
    hCell = calendarHeight / 7;

    d3.select("body")
        .on("keydown", keydownHandler)
    ;

    update();

});

function update() {

    updateCalendar();

    updateRing();

}

function updateCalendar() {

    var days =
        _(d3.time.days(firstDay, lastDay))
        .map(function(day) {
            return {
                "day": day,
                "lfp": _(lfpData).find(function(x) {
                    return x.date.toDateString() === day.toDateString();
                }),
            };
        })
        .value()
    ;

    var g = calendarGroup.selectAll("g")
        .data(days, function(d) { return d.day; })
    ;

    var gEnter = g.enter()
        .append("g")
        .attr("transform", function(d) {
            var x = (week(d.day) - week(firstDay)) * wCell;
            var y = day(d.day) * hCell;
            return "translate(" + x + " " + y + ")";
        })
    ;

    gEnter
        .append("rect")
        .attr("width", wCell)
        .attr("height", hCell)
        .attr("fill", function(d) {
            return color(month(d.day));
        })
        .attr("stroke", "black")
        .attr("stroke-width", 2)
        .attr("stroke-linecap", "round")
    ;

    var textGroup =
        g
        .append("g")
        .attr("transform", "translate(0 2)")
    ;

    textGroup
        .append("text")
        .attr("x", wCell/2)
        .attr("y", 0)
        .text(function(d) {
            return format(d.day);
        })
    ;

    var textGroupWithLfp =
        textGroup
        .filter(function(d) {
            return d.lfp !== undefined;
        })
    ;

    textGroupWithLfp
        .append("text")
        .attr("x", wCell/2)
        .attr("y", hCell/3)
        .text(function(d) {
            return d.lfp.topic;
        })
    ;

    textGroupWithLfp
        .append("text")
        .attr("x", wCell/2)
        .attr("y", 2*hCell/3)
        .text(function(d) {
            return d.lfp.name;
        })
    ;

    g
        .style("opacity", function(d) {
            return month(d.day) === displayedMonth ? 1.0 : 0.5;
        })
    ;

    calendarGroup
        .transition()
        .duration(600)
        .attr("transform", function() {
            var firstWeek = +week(firstDay);
            var firstWeekToDisplay = + week(mkDate(2014, displayedMonth, 1));
            var deltaWeek = firstWeekToDisplay - firstWeek;
            return "translate(-" + deltaWeek * wCell + " 0)";
        })
    ;

    g
        .exit()
        .selectAll("text")
        .transition()
        .duration(3000)
        .style("opacity", 0)
        .remove
    ;

}

function updateRing() {

    var data =
        d3.nest()
        .key(function(d) { return d.group; })
        .rollup(function(d) {
            //console.log(d.length, d);
            return d.length;
        })
        .entries(lfpData)
    ;

    var pie = d3.layout.pie()
        .value(function(d) {
            return d.values;
        })
    ;

    var gs =
        ring
        .selectAll("g")
        .data(pie(data))
    ;

    var gsEnter =
        gs.enter()
        .append("g")
        .attr("transform", "translate(" + outerRadius + ", " + outerRadius + ")")
    ;

    gsEnter
        .append("path")
        .attr("fill", function(d, ndx) {
            return color(ndx);
        })

    gsEnter
        .append("text")
    ;

    gs
        .select("path")
        .attr("d", arc)
    ;

    gs
        .select("text")
        .attr("transform", function(d) {
            return "translate(" + arc.centroid(d) + ")";
        })
        .transition()
        .duration(3000)
        .text(function(d) {
            return d.data.key + " (" + d.value + ")";
        })
    ;

}

function keydownHandler() {

    switch (d3.event.keyCode) {

    case 37: // Left
        displayedMonth--;
        break;

    case 39: // Right
        displayedMonth++;
        break;

    };

    displayedMonth = Math.max(displayedMonth, month(firstDay));
    displayedMonth = Math.min(displayedMonth, month(lastDay));

    update();

}
