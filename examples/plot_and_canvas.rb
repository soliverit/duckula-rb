Lpr.info """
Sample canvas and graph examples

Draw a Cross and a other angle cross... then
merge the two
"""
canvasWidth 	= PARAMETERS[:"--canvas-width"] || 25
canvasHeight 	= PARAMETERS[:"--canvas-height"] || 25
crossScale		= PARAMETERS[:"--scale"] || 1.0

Lpr.d "Create: Canvas #{canvasHeight} rows and #{canvasWidth} columns"

graphCanvas = GraphCanvas.new canvasWidth, canvasHeight

Lpr.p """
##
# Draw a cross by creating some lines and applying them to the canvas
##
"""
Lpr.d "Create lines"
line1 	= GraphLine.new CanvasCoordinate.new(canvasWidth / 2, 0), CanvasCoordinate.new(canvasWidth / 2 , canvasHeight - 1)
line2	= GraphLine.new CanvasCoordinate.new(0, 0), CanvasCoordinate.new(canvasWidth - 1, canvasHeight - 1)
unless PARAMETERS[:"--skip-lines"]
	Lpr.d "Apply line to canvas"
	graphCanvas.draw line1

	Lpr.d "Render canvas with first line"
	graphCanvas.render

	Lpr.d "Render canvas with both lines"
	graphCanvas.draw line2
	graphCanvas.render
end

Lpr.info """
Creating a Scatter plot
"""
scatterGraph = ScatterGraph.new width=60, height=25,name="My Scatter Sandbox"

scatterGraph.addSeries Series.new("Series 1", [[1,1], [5,4], [2, 3], [7, 5]], 0, :blue, "o")
scatterGraph.addSeries Series.new("Series 2", [[1,1], [5,7], [4, 3], [3, 3]], 0, :red)
scatterGraph.legend = true
scatterGraph.render
