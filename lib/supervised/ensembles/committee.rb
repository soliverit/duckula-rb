require_relative "./supervised_ensemble_base.rb"
class Committee
	DEFAULT_PARAMS = {
		machineCount: 	4,
		featureCount:	8
	}
	def initialize rgDataSet, target, machineClass, parameters
		super rgDataSet, target, machineClass, parameters
		@committee	= false
		@machines	= MachineSet.new 
		DEFAULT_PARAMS.each{|key, value| @parameters[key] ||= value}
	end
	def randomFeatures
		rgDataSet.features.shuffle[0, @parameters[:featureCount]]
	end
	def train
		##
		# Generate N machines on random features	
		##
		(0...@parameters[:machineCount]).each{
			
			newMachine = @machineClass.new(@trainingData.segregate(@, @target, {})
			newMachine.train 
			@machines.push newMachine 
		}
		groupPredictions = @machines.predictWithAll @testData, @testTargets
		
	end

end