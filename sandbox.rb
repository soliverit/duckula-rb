system "ruby run_example.rb simple_tuning --data-alias:ncm_reduced --target:ber "
exit
require "./ollie_ml.rb"

rgDataSet = RegressionDataSet.parseCSV "./data/simple_relational_data.csv"

yearHash = Hash[(1981..2013).each_with_index.map{|y, idx|[ y.to_s, idx]}]
rgDataSet.apply{|data|
	data[:YearX] = yearHash[data[:YearX].to_i.to_s]
	data[:YearY] = yearHash[data[:YearY].to_i.to_s]
}
target		= :target
splitData 	= rgDataSet.split 0.4
trainData	= splitData.first
testData	= splitData.last
testTargets	= testData.retrieveFeatureAsArray target
testData.dropFeatures [:target]
OllieUtilities::trainTestAndPrintError RubyLinRegression, trainData, testData, testTargets, target, {silentMode: false}