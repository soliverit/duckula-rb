Lpr.info """
Behold!

Err, here's a simple k-means clustering and plotting example
using data.csv
"""

Lpr.info "Simple K-Means clustering"
if ! INPUT_DATA_PATH
	Lpr.info "Input data path has not been created due to the absence of the --data-alias parameter"
	return
end
Lpr.info """
Create a K-Means clustering model using the #{PARAMETERS[:"--targets"]}
"""
Lpr.d "Loading data: #{INPUT_DATA_PATH}"
rgDataSet 	= RegressionDataSet.parseCSV(INPUT_DATA_PATH)

Lpr.p "Make sure --targets exist"
failed = false
puts Lpr.hashToRows(Hash[PARAMETERS[:"--targets"].map{|target| 
	failed = true if ! rgDataSet.features.include?(target)
	[target, rgDataSet.features.include?(target).to_s]
}])
if failed
	Lpr.info "Data set's features don't contain some features. Exiting"
	return
end
clusters = PARAMETERS[:"--clusters"] ? PARAMETERS[:"--clusters"].to_i : 4
Lpr.d "Splitting RegressionDataSet into a small test and large train data sets"
rgSets = rgDataSet.filterByFunction{|data| data[:ser] == 0}.split(0.05)
Lpr.d "Creating K-Means clusterer with #{clusters}"
model		= KMeans.new rgSets.last, PARAMETERS[:"--targets"], {clusters: clusters}
model.train
results = model.predictSet(rgSets.first.segregate(PARAMETERS[:"--targets"]))
Lpr.info """
Create plot of data
"""
resultsGroups = {}
results.set.each{|prediction| 
	resultsGroups["K-" + prediction.prediction.to_s] ||= []
	resultsGroups["K-" + prediction.prediction.to_s].push prediction
}

scatterGraph = ScatterGraph.new 110, 55, "Scatter K-Means"
scatterGraph.legend = true
scatterGraph.legendSort{|a, b| a.to_s.match(/\d+/).to_s.to_i <=> b.to_s.match(/\d+/).to_s.to_i}
resultsGroups.each{|key, group|
	i = Random.rand(10) + 35
	scatterGraph.addSeries(
		Series.new( key, 
				group.map{|prediction| [prediction.input.first, prediction.input[1]]},
				1.0, 
				CanvasPixel.colours.keys.sort{Random.rand <=> Random.rand}.first,
				i.chr))
}

scatterGraph.render

######
# Line Graph
######
#Create and add legend
lineGraph 			= LineGraph.new 175, 40, "Line Graph K-Means"
lineGraph.legend 	= true
#Create and add series
lineGraph.addSeries Series.new("Example", [5,10,12, 12, 12], 1.0, :white, "x")
lineGraph.addSeries Series.new("Example 2", [2,4,8, 16, 3], 1.0, :blue, "x")
#
lineGraph.render