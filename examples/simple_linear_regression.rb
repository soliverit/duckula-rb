Lpr.p """
##
# Load the sample data and split into train/test.
#
# If the input data doesn't exist log and exist
#
# NOTE:
# 	If a second argument is passed to the command line it will be used
#	as the input data file name. File must be in ./data/ and doesn't include
#	the ./data/ part, just the file name.
#
# ADDITIONAL command line parameters (after example name)
#	second:	Input data csv name (located in ./data/). Must end in .csv
#	third:	Enables silent mode if its value is 'silent'
##
"""
Lpr.d "Checking input data file exists"
dataPath = INPUT_DATA_PATH # ARGV[1] && ARGV[1].to_s.downcase.match(/\.csv$/) ? "#{DATA_PATH}#{ARGV[1]}" : "#{DATA_PATH}data.csv"
unless File.exists? dataPath
	Lpr.d "Input data path '#{dataPath}' doesn't exist"
	return
end
SILENT_MODE		= ARGV.find_index{|val| val.to_s.downcase == "silent"}
Lpr.d "Loading input data"
rgDataSet = RegressionDataSet.parseCSV dataPath

Lpr.d "Splitting data into train/test. Input parameter is how much goes to first set"
target			= PARAMETERS[:"--target"] || :target
trainTestSplit 	= rgDataSet.split PARAMETERS[:"--split"] || 0.5
trainData		= trainTestSplit.first
testData		= trainTestSplit.last
testTargets		= testData.retrieveFeatureAsArray target
testData.dropFeatures [target]
Lpr.p """
##
# Use RegressionDataSet to print a summary of its features.
##
"""
rgDataSet.printFeatureSummary
Lpr.p """
##
# Train and test some models from the supported libraries
#
#	- RubyLinRegression
# 	- LibLinRegression
#	- SVM
#	- LogisticRegression 
#
# Every model uses the same instaniation method, train, predict,
# validate, etc... Even Fast-ANN (though it's a bit more complicated 
# for results
#
# OllieMlBase.new parameters:
#	data:		Training data
#	Target:		Symbol for target key (dropped automatically when training
#	Parameters:	Hash of parameters. You'll need to look at the code for these.
#				Each model is different.
#
#	IMPORTANT NOTE:
#		The OllieMlBase (base class for all  models)'s validateSet method is 
#		for supervised estimation. Unlike predict, it takes a third parameter
#		which defines the type of prediction class should be used. For the most part
#		you'll just want to use Prediction, though the DomainRejectionPrediction is
#		pretty cool. It's designed to let you score based on either all data or only
#		those within a certain tolerance
#
#	WARNING:
#		- Don't use X or Y as variable names. Ruby doesn't like redefining constants
##
"""

def trainTestAndPrintError modelClass, trainData, testData, testTargets, target, parameters = {}
	Lpr.info "#{modelClass} model"
	puts trainData.features.to_json
	model 			= modelClass.new trainData, target, parameters
	puts model.describeHyperparameters
	model.train
	predictionSet 	= model.validateSet testData, testTargets, DomainRejectionPrediction
	
	results			= predictionSet.reduceByRejection.getError
	results.printOut 
	##
	#Do a Scatter plot
	##
	scatterGraph	= ScatterGraph.new 60, 30, modelClass.name
	scatterGraph.legend = true
	
	seriesValues 	= predictionSet.reduceByRejection.set.map{|prediction| [prediction.expected, prediction.prediction]}
	series			= Series.new "BER estimation", seriesValues, 1, :red, "*"
	scatterGraph.addSeries series
	
	scatterGraph.render
	exit
end
Lpr.d "RubyLinRegression - Standard"
trainTestAndPrintError RubyLinRegression, trainData, testData, testTargets, target, {silentMode: SILENT_MODE}
Lpr.d "RubyLinRegression - Gradient Descent"
trainTestAndPrintError RubyLinRegression, trainData, testData, testTargets, target, {lRate: 0.0005, iterations: 20, gradientDescent: true, silentMode: SILENT_MODE}

Lpr.d "EPSRegressor - WARNING: This is clearly not set up for the example (or at all, who knows)"
trainTestAndPrintError EPSRegressor, trainData, testData, testTargets, target, {}
																				
Lpr.d "LibSvm - Standard kernel"
trainTestAndPrintError LibSvmRegressor, trainData, testData, testTargets, target, {gradientDescent: true, silentMode: SILENT_MODE}
		
Lpr.d "Fast-ANN - Standard kernel"
trainTestAndPrintError FastANN, trainData, testData, testTargets, target, {max_mse: 1, silentMode: SILENT_MODE}
		
### TODO: Figure out how LibLinLogisticRegressor works		
# LibLinLogisticRegressor
# Lpr.d "LibSvm - Standard kernel"
# trainTestAndPrintError LibLinLogisticRegressor, trainData, testData, testTargets, target, {gradientDescent: true, silentMode: SILENT_MODE}
	
