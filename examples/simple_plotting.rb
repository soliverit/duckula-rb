######
# Line Graph
######
#Create and add legend
lineGraph 			= LineGraph.new 175, 40, "Line Graph K-Means"
lineGraph.legend 	= true
#Create and add series
lineGraph.addSeries Series.new("Example", (0..15).map{[0,Random.rand(15).to_i]}, 1.0, :white, "x")
# lineGraph.addSeries Series.new("Example 2", (0..15).map{[0, Random.rand(15).to_i]}, 1.0, :blue, "x")
#Render
# lineGraph.render
##
# Scatter Graph
##
#Create and add legend
scatterGraph 		= ScatterGraph.new 100, 40, "Simple Line"
scatterGraph.legend = true
#Create and add series
scatterGraph.addSeries Series.new("1:", (0..25).map{[Random.rand(39).to_i, Random.rand(39).to_i]}, 1.0, :white, "$", true)
scatterGraph.addSeries Series.new("2:", (0..25).map{[Random.rand(39).to_i, Random.rand(39).to_i]}, 1.0, :red, "+")
#Render
scatterGraph.render
