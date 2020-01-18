##
# Includes
##
## Native ##
require "ruby-fann"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Fast ANN - ruby-fann										   	#
#																#
# 		WORK IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!!!!				#
#################################################################
class FastANN < OllieMlSupervisedBase
	@@defaultParameters = {
		max_epochs: 	5000,
		error_count:	500,
		max_mse:		80.0,
		hidden_neurons: [2, 8, 4, 3, 4],
		num_outputs:	1
	}
	##
	# OVERRIDDEN!
	# Tell whoever asks that this is a neural network
	##
	def self.isNN?
		true
	end
	##
	# @trainingData:	RegressionDataSet excluding the target
	# @targets:	2D array of targets, if 1D passed in it's translated
	# @parameters:		Network hyper parameters
	# @trainer:			ANN TrainerData object
	# @lr:				Fast-ANN - RubyFann::Standard
	##
	def initialize data, target, parameters
		super(data, target, parameters)
	end
	##
	# OVERRIDDEN!
	# Set the hyper parameters.
	#
	# Notes:
	#	- Like quaternions, don't pretend to understand the or use them,
	#	  just accept that they're right, otherwise you'll break everything.
	#	- Alternatively, go nuts! Maybe implementing some back propagation thing will
	#	  make this useful or someone else might use it...
	##
	def setParameters parameters
		@@defaultParameters.keys.each{|key|
			@parameters[key] =  parameters[key] ? parameters[key] : @@defaultParameters[key]
		}
	end
	##
	# OVERRIDDEN!
	# Train the Fast-ANN
	##
	def train
		@trainer 	= RubyFann::TrainData.new(
			inputs: 			trainingData, 
			desired_outputs: 	trainingTarget
		)
		@lr			= RubyFann::Standard.new(
			num_inputs:			@parameters[:num_inputs],
			hidden_neurons: 	@parameters[:hidden_neurons], 
			num_outputs: 		@parameters[:num_outputs]
		)
		@lr.train_on_data(
			@trainer,
			@parameters[:max_epochs],
			@parameters[:error_count],
			@parameters[:max_mse].to_f
		)
	end
	def trainingData
		if @target.class == Symbol
			output = super.getDataStructure(useHash)
		elsif @trainingData.class == Array
			output = @trainingData.dup
		else
			output = @trainingData.getDataStructure(useHash)
		end
		@parameters[:num_inputs] = output.first.length
		output
	end
	def trainingTarget
		if @target.class == Symbol
			output = @trainingData.retrieveFeatureAsArray(@target).map{|val| [val]}
		else
			######## WORK IN PROGRESS !! DEAL WITH IMPLICIT TARGETS HERE ######
			output = @target
		end
		@parameters[:num_outputs] = output.first.length
		output
	end
	##
	# OVERRIDDEN!
	# Make a prediction
	#
	# Unlike everything else, they named predict run.... Sigh.
	##
	def predict input
		@lr.run(input)
	end
end
