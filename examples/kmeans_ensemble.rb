Lpr.info """
K-Means clustering method for ML optimisation
Calibrate a k-means cluster regressor ensemble
using features importance analysis to select cluster
properties.
""", "#"
Lpr.hashToTable PARAMETERS
if ! PARAMETERS[:"--data-alias"]
	Lpr.info "Error: --data-alias method not present", "!"
	return
elsif !File.exists? PARAMETERS[:"--data-alias"]
	Lpr.info "Error: --data-alias file path (#{PARAMETERS[:"--data-alias"]})doesn't exist"
	return
end
Lpr.info """
Load data

Target feature: #{PARAMETERS[:"--target"]}
""", "-"
Lpr.d "Parse #{PARAMETERS[:"--data-alias"]}"
rgDataSet = RegressionDataSet.parseCSV PARAMETERS[:"--data-alias"]
Lpr.d "Scale and translate features to integers"

Lpr.d "Print information about input data"

# rgDataSet.printFeatureBounds
Lpr.d "Split data into test / train"
trainTestSets	= rgDataSet.split(PARAMETERS[:"--tt-split"])
trainData		= trainTestSets.first
testData		= trainTestSets.last
targetValues	= testData.retrieveFeatureAsArray PARAMETERS[:"--target"]
testData.dropFeatures [PARAMETERS[:"--target"]]
Lpr.info """
Create a linear regressor for sensitivity analysis


"""
Lpr.d "Build RubyLinRegression regressor"
model = RubyLinRegression.new trainData, PARAMETERS[:"--target"], {}
Lpr.d "Train model"
model.train
Lpr.d "Test model and print results"
validationSet = model.validateSet testData, targetValues, Prediction
puts validationSet.getError.printOut
Lpr.info """
Create a Random Forest for sensitivity analysis
"""
system "cls"
rfModel = XGBoost.new trainData, PARAMETERS[:"--target"], {}

rfModel.train