# ##
# # Includes
# ##
# ## Native ##
# require "xgb"
# ## Library ##
# require "./lib/ollie_ml_supervised_base.rb"
# #################################################################
# # XGBoost
# #################################################################

# class XGBoost < OllieMlSupervisedBase
	
	# def initialize data, target, parameters
		# raise "XGBoost not yet implemented"
		# super data, target, parameters
	# end
	# def train
	# (0..5).each{puts "==============="}
		# rgDataSet = Xgb::DMatrix.new([[1,2],[1,4]], label:[1,2,3])
		# exit
		# # puts trainingTarget.retrieveFeatureAsArray(@target).to_json
		# # Xgb::DMatrix.new(x, label: y)
		# xgbData = Xgb::DMatrix.new( trainingData.data, label: trainingTarget.retrieveFeatureAsArray(@target))
		# exit
		# @lr		= Xgb.train(parameters, xgbData)
	# (0..5).each{puts "-----------"}	
	# end
	# def parameters
		# {objective: "reg:squarederror"}
	# end
# end
