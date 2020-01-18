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
model		= KMeans.new rgDataSet, PARAMETERS[:"--targets"], {}
model.train

