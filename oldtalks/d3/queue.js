
var newColor = (function() {
    var color = d3.scale.category20();
    var counter = 0;
    return function() {
        return color(counter++);
    };
})();

var myData = [ newColor(), newColor(), newColor() ];

var separation    = 10;
var elementWidth  = 300;
var elementHeight = 30;
var maxNbElements = 8;
var animDelay     = 1000;

var svg;

function yPos(ndx) {
    var ndx = maxNbElements - ndx - 1;
    return (ndx + 1) * (elementHeight + separation);
}

$(document).ready(function() {

    var stackWidth =
        elementWidth + 2 * separation
    ;

    var stackHeight =
        maxNbElements * elementHeight
        + (maxNbElements + 1) * separation
    ;

    svg =
        d3.select("body")
        .append("svg")
        .attr("width", stackWidth)
        .attr("height", stackHeight + 2 * elementHeight)
    ;

    svg
        .append("rect")
        .attr("fill", "orange")
        .attr("width", stackWidth)
        .attr("height", stackHeight)
        .attr("y", elementHeight);
    ;

    $("body").append(
        $("<p>")
            .append(
                $("<button>")
                    .text("PUSH")
                    .click(function() {
                        push();
                        update();
                    })
            )
            .append(
                $("<button>")
                    .text("POP")
                    .click(function() {
                        pop();
                        update();
                    })
            )
    );

    update();

});

function update() {

    var rectangles =
        svg.selectAll("rect.element")
        .data(myData, function(d) { return d; })
    ;

    rectangles.enter()
        .append("rect")
        .attr("class", "element")
        .attr("fill", function(d) { return d; })
        .attr("width", elementWidth)
        .attr("height", elementHeight)
        .attr("x", separation)
        .attr("y", 0)
        .attr("opacity", 0)
    ;

    rectangles
        .transition()
        .duration(animDelay)
        .attr("y", function(d, ndx) { return yPos(ndx); })
        .attr("opacity", 1)
    ;

    rectangles.exit()
        .transition()
        .duration(animDelay)
        .attr("y", yPos(-1))
        .attr("opacity", 0)
        .remove()
    ;

}

function push() {
    if (myData.length == maxNbElements) {
        pop();
    }
    myData.push(newColor());
}

function pop() {
    myData.shift();
}
