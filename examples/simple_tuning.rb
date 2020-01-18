if ! INPUT_DATA_PATH
	Lpr.p "Exiting: No input data path found"
	return
end
if ! PARAMETERS[:"--target"]
	Lpr.p"Exiting: No --target defined"
end

Lpr.info """
Simple Linear Regression hyper parameter tuning using LibSvm
"""
Lpr.d "Loading data and splitting to train/test"
rgDataSet 	= RegressionDataSet.parseCSV(INPUT_DATA_PATH)
# rgDataSet.normalise = true
rgDataSets	= rgDataSet.split(PARAMETERS[:"--split"] || 0.4)

trainData	= rgDataSets.first
testData	= rgDataSets.last

Lpr.d "Loaded #{trainData.length} training and #{testData.length} test records"
Lpr.d "Declaring :learnRate and "
tunerParams = [ 
	TunerParameter.new(:c, 5, 200, true), 
	TunerParameter.new(:eps, 0.0005, 0.1),
	TunerParameter.new(:gamma, 0.01, 0.2),
	TunerParameter.new(:nu, 0.1, 0.5)
	# TunerSetParameter.new(:kernel_type, ["C-SVC"]),
	# TunerSetParameter.new(:svm_type, ["one-class SVM","epsilon-SVR"])
] 

Lpr.d "Creating tuner"
hpTuner = HyperbandTuner.new LibSvmRegressor, tunerParams, {}

Lpr.d "Tune model"
hpTuner.tune trainData, testData, PARAMETERS[:"--target"]

