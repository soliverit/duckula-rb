##
# Includes
##
## Native ##
require "eps"
## Library ##
require "./lib/ollie_ml_supervised_base.rb"
#################################################################
# Standard regression model based on the EPS Regressor			#
#																#
# Nothing exciting to add, trains very fast gets the result		#
# expected as RubyRubyLinRegression.train_normal_equation		#
#################################################################
class EPSRegressor < OllieMlSupervisedBase
	def self.useTargetKey?
		true
	end
	##
	# data:				RegressionDataSet
	# target:			Target name. Symbol
	#
	# @trainingData:	Training data including @targetKey values
	# @target:			Training target
	# @lr:				EpsRegressor for the normal equation
	##
	def initialize data, target, parameters
		super(data, target, parameters)
	end
	def train
		@lr ||= Eps::Regressor.new(@trainingData.getDataStructure(useHash), target: @target)
	end
	##
	# OVERRIDDEN!
	# Class inheritance abuse. Tell it to use RegressionDataSet.hashedData
	##
	def useHash 
		true
	end
	##
	# Print model summary
	##
	def summary
		puts @lr.summary
	end
	def getFeatureData rgDataSet
		rgDataSet.segregate features.select{|feature| feature != @target}
	end
end
