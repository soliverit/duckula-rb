require "./lib/print_helper.rb"
# require "./configs/supervised.rb"
# require "./configs/predictions.rb"
require "./lib/regression_data_set.rb"
require "./lib/supervised/eps_regressor.rb"
require "./lib/predictions/prediction.rb"
Lpr.startTimer
Lpr.silentMode = true

require "json"

if ! ARGV.first || ! ARGV[1]
	Lpr.p "###
# Parameters:
#	First:	Target column name - #{ARGV.first ? "Found": "Missing"}
#	Second:	Input data path - #{ARGV[1] ? "Found": "Missing"}
###"
	if ARGV[1] && ! File.exists?(ARGV[1])
		Lpr.p"### Input data path doesn't exist ###"
	end
exit
end
##
# Load model feature list
##
TARGET			= ARGV[0].to_sym
INPUT_DATA_PATH	= ARGV[1] + "/input.csv"
CONS_DATA_PATH	= ARGV[1] + "/wall_constructions.csv"
TEMP_PATH		= ARGV[1] + "/temp.csv"
OUTPUT_PATH		= "./depc.csv"
FEATURES		= File.open("domestic_features.txt").each_line.map{|line| line.strip.to_sym}
Lpr.d "### Set target, features and input data path ###"
##
# Load middlesborough sample and split
##
rgDataSet 	= RegressionDataSet.parseGemCSV(INPUT_DATA_PATH).segregate [FEATURES, TARGET].flatten #"C:\\university\\sandbox\\catified\\domestic-E06000002-Middlesbrough.csv"	
Lpr.d "### Loaded #{INPUT_DATA_PATH} ###"

Lpr.p "###
# Feature engineering
###"

Lpr.d "Do construction age band"
AGE_BAND_ENUMS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]
rgDataSet.apply{|data|
	data[:CONSTRUCTION_AGE_BAND] = AGE_BAND_ENUMS.find_index data[:CONSTRUCTION_AGE_BAND]
}
###############################################

Lpr.d "Do is flat or house or bungalow?"
rgDataSet.injectFeatures({	IS_FLAT: 0,	IS_HOUSE: 0, 
							IS_BUNGALOW: 0, IS_MAISONETTE: 0})
rgDataSet.apply{|data|
	case data[:PROPERTY_TYPE].to_s
	when "Bungalow"
		data[:IS_BUNGALOW] = 1
	when "House"
		data[:IS_HOUSE] = 1
	when "Flat" 
		data[:IS_FLAT] = 1
	else
		data[:IS_MAISONETTE] = 1
	end
}
rgDataSet.dropFeatures [:PROPERTY_TYPE]
###############################################

Lpr.d "Do extension count. It's dirty! (add missing values)**"
rgDataSet.apply{|data|
	unless data[:EXTENSION_COUNT].to_s.match(/\d/)
		data[:EXTENSION_COUNT] = 0
	end
}
###############################################

Lpr.d "Do is top storey"
rgDataSet.apply{|data|data[:FLAT_TOP_STOREY] = data[:FLAT_TOP_STOREY].downcase == "y" ? 1 : 0}

###############################################

Lpr.d "Do Built form (NOTE: I'd watch semi-d and end-t are the same here)"
rgDataSet.injectFeatures({	IS_DETACHED: 0, 
							IS_SEMI_DETACHED: 0, IS_END_TERRACE: 0,
							IS_ENCLOSED_MID_TERRACE: 0, IS_ENCLOSED_END_TERRACE: 0})
rgDataSet.apply{|data|
	case data[:BUILT_FORM].to_s
	when "Detached"
		data[:IS_DETACHED] = 1
	when "Mid-Terrace"
		data[:IS_SEMI_DETACHED] = 1
	when "End-Terrace"
		data[:IS_END_TERRACE] = 1
	when "Semi-Detached"
		data[:IS_SEMI_DETACHED] = 1
	when "Enclosed Mid-Terrace"
		data[:IS_ENCLOSED_MID_TERRACE] = 1
	when "Enclosed End-Terrace"
		data[:IS_ENCLOSED_END_TERRACE] = 1
	end
}
rgDataSet.dropFeatures [:BUILT_FORM]
###############################################

Lpr.d "Do mains gas flag"
rgDataSet.apply{|data| data[:MAINS_GAS_FLAG] = data[:MAINS_GAS_FLAG] == "Y" ? 1 : 0}
###############################################

Lpr.d "Do is it bottom, top or anywhere else floor of flat"
rgDataSet.injectFeatures({IS_BASEMENT: 0, IS_ROOF: 0})
rgDataSet.apply{|data|
	case data[:FLOOR_LEVEL].to_s
	when /basement/i
		data[:IS_BASEMENT] = 1
	when /ground/i
		data[:FLOOR_LEVEL] = 0
	when /top/i
		data[:IS_ROOF] = 1
	else
		data[:FLOOR_LEVEL] = 1
	end
}
rgDataSet.dropFeatures [:FLOOR_LEVEL]
###############################################

Lpr.d "Do Energy Tarif"
rgDataSet.apply{|data|
	case data[:ENERGY_TARIFF]
	when /single/i
		data[:ENERGY_TARIFF] = 0
	when /dual/i
		data[:ENERGY_TARIFF] = 1
	else
		data[:ENERGY_TARIFF] = -1
	end
}
###############################################

Lpr.d "Transform FLOOR construction to U-Values or filter flags (false)"
Lpr.d "SUPER WARNING: This is missing so much that we need a temp value"
Lpr.d "SUPER WARNING: Cont'd... so we'll stick this in for now"
Lpr.d "SUPER WARNING: Cont'd... and see how it goes. Harass Saleh if it comes to it"

rgDataSet.apply{|data|
	matchedUvalue = data[:FLOOR_DESCRIPTION].match(/(\d\.\d{0,3})\s*W/)
	if matchedUvalue
		data[:FLOOR_DESCRIPTION] = matchedUvalue[1].to_f
	else
		data[:FLOOR_DESCRIPTION] = -1
	end
}
###############################################

#Lpr.d "Source: https://www.bre.co.uk/filelibrary/SAP/2012/RdSAP-9.93/RdSAP_2012_9.93.pdf"
Lpr.d "Do wall constructions!"
Lpr.d "SUPER WARNING: This is missing so much that we need a temp value"
Lpr.d "SUPER WARNING: Cont'd... so we'll stick this in for now"
Lpr.d "SUPER WARNING: Cont'd... and see how it goes. Harass Saleh if it comes to it"
		
rgDataSet.apply{|data|
	matchedUvalue = data[:WALLS_DESCRIPTION].match(/(\d\.\d{0,3})\s*W/)
	if matchedUvalue
		data[:WALLS_DESCRIPTION] = matchedUvalue[1].to_f
	else
		data[:WALLS_DESCRIPTION] = -1
	end
}
###############################################

Lpr.d "Do glazed area stuff - NOTE: Glazed area is enumerated in rdSAP"
GLAZED_AREA_ENUMS = ["NO DATA!","Less Than Typical", "Normal", "More Than Normal",
 "Much More Than Normal"]
rgDataSet.apply{|data|
	data[:GLAZED_AREA] = GLAZED_AREA_ENUMS.find_index data[:GLAZED_AREA]
}
###############################################

Lpr.d "Do multiglazed portion"
rgDataSet.apply{|data|
	unless data[:MULTI_GLAZE_PROPORTION].to_s.match(/\d/)
		data[:MULTI_GLAZE_PROPORTION] = 0
	end
}
###############################################

Lpr.d "Flag number of heated rooms / inhabitable rooms for cleansing"
rgDataSet.apply{|data|
	unless data[:MULTI_GLAZE_PROPORTION].to_s.match(/\d/)
		data[MULTI_GLAZE_PROPORTION] = 0
	end
}

Lpr.d "Do window *constructions* (LOL)"
Lpr.d "WARNING: Just kidding, there's no explicit window u-value or g-values"
###############################################

Lpr.d "OK! Do all the _ENERGY_EFF enumerated values"
QUALITY_ENUMS = ["Very Poor", "Poor", "Average", "Good", "Very Good"]
[:HOT_WATER_ENERGY_EFF, :LIGHTING_ENERGY_EFF, :ROOF_ENERGY_EFF, 
 :WALLS_ENERGY_EFF, :WINDOWS_ENERGY_EFF, :MAINHEAT_ENERGY_EFF].each{|effKey|
	rgDataSet.apply{|data|
		if data[effKey] == "N/A"
			data[effKey] = 0
		else
			data[effKey] =QUALITY_ENUMS.find_index data[effKey]
		end
	}
}
###############################################

Lpr.d "Do heat loss corridor stuff"
HEAT_LOSS_CORRIDOOR_ENUMS = [ "heated corridor", "unheated corridor"]
rgDataSet.apply{|data|
	if data[:HEAT_LOSS_CORRIDOOR] == "NO DATA!"
		data[:HEAT_LOSS_CORRIDOOR] = 0
	elsif data[:HEAT_LOSS_CORRIDOOR] == "no corridor"
		data[:HEAT_LOSS_CORRIDOOR] = 0
	else
		data[:HEAT_LOSS_CORRIDOOR] = HEAT_LOSS_CORRIDOOR_ENUMS.find_index data[:HEAT_LOSS_CORRIDOOR]
	end
}
###############################################

Lpr.d "Do mechanical ventilation"
rgDataSet.enumerate :MECHANICAL_VENTILATION
###############################################

Lpr.d "Do lighting fixture stuff"
rgDataSet.apply{|data|
	unless data[:LOW_ENERGY_FIXED_LIGHT_COUNT].to_s.match(/\d/)
		data[:LOW_ENERGY_FIXED_LIGHT_COUNT] = 0
	end
	unless data[:FIXED_LIGHTING_OUTLETS_COUNT].to_s.match(/\d/)
		data[:FIXED_LIGHTING_OUTLETS_COUNT] = 0
	end
}
###############################################


Lpr.d "Do hot water description"
Lpr.d "WARNING: This is a bugger since hot water is the primary indicator of residential consumption"
Lpr.d "WARING: Cont'd. I'd wager decision trees handle enums fine, not line reg (see other discussion)"
rgDataSet.enumerate :HOTWATER_DESCRIPTION

Lpr.d "Do mains fuel"
Lpr.d "WARNING: Like hot water + there's a lot of values here but we probably only need 4"
Lpr.d "NOTE: All we really need is a CO2 factor roughly"
rgDataSet.apply{|data|
	case data[:MAIN_FUEL]
	when /electricity/i
		data[:MAIN_FUEL] = 0.519
	when /community/i
		data[:MAIN_FUEL] = 0.24
	when /lpg/i
		data[:MAIN_FUEL] = 0.269
	when /oil/
		data[:MAIN_FUEL] = 0.34
	when /gas/i
		data[:MAIN_FUEL] = 0.216
	else
		data[:MAIN_FUEL] = -1
	end
}
###############################################


Lpr.d "Prepare ROOM data cleansing flags. Can't calculate without data!!!"
rgDataSet.apply{|data|
	unless data[:NUMBER_HABITABLE_ROOMS].to_s.match(/\d/)
		data[:NUMBER_HABITABLE_ROOMS] = false
	end
	unless data[:NUMBER_HEATED_ROOMS].to_s.match(/\d/)
		data[:NUMBER_HEATED_ROOMS] = false
	end
}
###############################################

Lpr.d "Finally: Fix and enumerate heating controls"
rgDataSet.enumerate :MAIN_HEATING_CONTROLS
###############################################


Lpr.p "###
# Moment of truth. Dump the data and make sure it's good to go
###"
rgDataSet.toCSVGem TEMP_PATH


###############################################
# Do the filtering and what not
###############################################

Lpr.p"###
# Rinse the data's mouth out with soap!
#
# There's three data integrity concerns we need to deal with
# when proving the model with incomplete data, beyond previous
# collation.
#
# 1) Duplicate data: If the model is just predicting what it's 
#	 seen then it's pointless
# 2) Unknown feature values: Some features like constructions 
#	 implicitly have associated values, u-value in their
#	 case. In rdSAP most have a u-value in the name
#	 or if it's external walls, an age band lookup
#	 table. Those that don't however, need new rough values.
#	 Initially, I guessed but that'll on ruin the dream of an
#	 easy life, so we'll just filter them out for now. Worry
#	 about finding rough values for them if generally works.
# 3) Incomplete data
# 
# So here, we're going to filter out some stuff 
###"

Lpr.d "Dataset size: #{rgDataSet.length}"
rgDataSet = rgDataSet.select{|data| data[:NUMBER_HEATED_ROOMS] && data[:NUMBER_HABITABLE_ROOMS]}
Lpr.d "Dataset size: #{rgDataSet.length} after filtering undefined room conditions"

Lpr.p "###
#  Let's train something, see what the damage is!
###"

modelData 		= rgDataSet.segregate([FEATURES, TARGET].flatten.uniq)
modelData.dropFeatures [:FLAT_TOP_STOREY]

models			= modelData.split 0.15
train			= models.first
test			= models.last
testTargetRgDS	= test.segregate [TARGET]
testTargets		= test.retrieveFeatureAsArray TARGET, true

##
# Train model
## 
# puts ObjectSpace.each_object(Class).select { |klass| klass < OllieMlSupervisedBase} 
Lpr.d "Training model"
[EPSRegressor].each{|modelClass|
	Lpr.d "Training: #{modelClass.name}"
	
	model 		= modelClass.new modelData, TARGET, {}
	model.train
	Lpr.d "Model trained"
	
	testData	= test.clone
	
	results 	= model.validateSet test, testTargets, Prediction
	results.getError.printTable
	
	testData 	<< results.toRgDataSet
	testData 	<< testTargetRgDS
	testData.toCSVGem OUTPUT_PATH	
	
	Lpr.d "Process complete for #{modelClass.name}"
}
exit

puts Dir.pwd
system "python example.py #{TARGET} #{TEMP_PATH}"
puts "python example.py #{TARGET} #{TEMP_PATH}"
exit

##
# Hyperband (not really) Tuner
##
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
hpTuner.tune modelData.first, modelData.last, target

