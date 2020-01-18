CSV_DATA_PATH 	=  "./data/geneva_schedule_climate.csv"

ELEC_COST 	= 0.153
GAS_COST 	= 0.034
ELEC_CO2	= 0.519
GAS_CO2		= 0.216
DPP_RATE	= 0.035
RETROFIT_COST = 83112


if ! CSV_DATA_PATH
	Lpr.p "Define CSV_DATA_PATH before continuing (I've got it in a data/ sub folder"
	return
end
Lpr.p """
## 
# Introduction / Overview
#
# Classes:
#	RegressionDataSet: 	The data handling library. Fun stuff, honestly
#	Lpr:				A printing prettifier
#
# Data:
#
# Starts with an alias, electricity and gas keys
#	alias:			String containing all the info on schedule, year, is retroffited
#	naturalGas:		kWh
#	electricity:	kWh
#
# alias key description:
# The data alias naming convention is original/explicit/implicit refers
# to the original model and occupancy schedules. upgraded-90 refers to 
# retrofitted models. These have full-<explicit/implicit/original> in their
# alias to dictate their occupancy schedule
#
# All weather data is for Geneva with a four digit year, 1981 to 2013
#
# WARNING:	RegressionDataSet doesn't handle Booleans yet, use string names
"""
## Load data

rgDataSet = RegressionDataSet::parseCSV CSV_DATA_PATH
Lpr.p """
##
# Fix alias inconsistency!
#
# Ok, this is on me. In my original data set I used 'full-or' to mean original schedule. Nonetheless,
# this is a good place to use the apply function to repair the broken alias.
#
##
"""
Lpr.d "fixing inconsistent alias"
rgDataSet.apply{|data|
	data[:alias].gsub!("full-or", "original")
}

Lpr.p """
##
# Add schedule and year alias keys. See proceeding comment in what aliases segments mean
##
"""
Lpr.d "Injecting schedule alias"
rgDataSet.injectFeatureByFunction(:schedule){|data, newKey|	data[:alias].match(/implicit|explicit|original/i).to_s }

Lpr.d "Injecting year"
rgDataSet.injectFeatureByFunction(:year){|data, newKey|	data[:alias].match(/\d{4}/).to_s.to_i}

Lpr.d "Injecting retrofited state"
rgDataSet.injectFeatureByFunction(:retrofitted){|data, newKey| (data[:alias].match(/upgraded-90/) ? true : false).to_s}
Lpr.d "Injecting energy cost"
rgDataSet.injectFeatureByFunction(:cost){|data, newKey| data[:electricity] * ELEC_COST + data[:naturalGas] * GAS_COST}

Lpr.d "Dumping to example_feature_inject_results.csv for review"
rgDataSet.toCSV "#{TMP_PATH}/example_feature_inject_results.csv"

Lpr.p """
##
# We're done with the alias feature. Though not necessary, we'll 
# drop it.
##
"""
Lpr.d "Dropping alias feature"
rgDataSet.dropFeatures	[:alias]

Lpr.p """
##
# Group the data
#
#
# Note: Grouping by function is available. If the alias feature was still present you could
#	\"'rgDataSet.groupByFunction{|data| data[:alias].match(/upgraded-90/) ? true : false}\"
#	to group by regex match for upgraded
#
# WARNING: This isn't actually used any more. Turns out it's unnecessary. Left in for demonstration
# purposes only.
##
"""
Lpr.d "Grouping by schedule"
rgRetrofittedGrouping 	= rgDataSet.groupBy(:schedule)
Lpr.p """
##
# Generate simple relational data set
#
# Features:
#	Original schedule, year
#	New schedule, year, deltaCO2
##
"""
simpleRelationalPayback = RegressionDataSet.new false, [:Original, :New, 
														:OriginalRetrofitted, :Retrofitted, 
														:YearX, :YearY, :target]
rgDataSet.each{|topData|
	# puts topData[:retrofitted].to_s.downcase == "false"
	rgDataSet.each{|data|
		next if data[:year] == topData[:year]
		next if data[:schedule] == "explicit" || topData[:schedule] == "explicit"
		deltaCO2 = ((topData[:electricity] - data[:electricity]) * ELEC_CO2 + (topData[:naturalGas] - data[:naturalGas]) * GAS_CO2) / 2869
		simpleRelationalPayback.push(
			[topData[:schedule] == "original" ? 0 : 1, 
			 data[:schedule] == "original" ? 0 : 1, 
				topData[:retrofitted].to_s.downcase == "false" ? 0 : 1, 
				data[:retrofitted].to_s.downcase == "false" ? 0 : 1,
										
										topData[:year], data[:year], deltaCO2]) 
	}
}
Lpr.d "Dumping #{simpleRelationalPayback.length} entries"
simpleRelationalPayback.toCSV "#{TMP_PATH}simple_relational_data.csv"
Lpr.p """
##
# Create martix of schedule-year data
#
# This will create a new RegressionDataSet which has the alias then every
# relevant year's delta cost from the start record on original data only
#
# Schedule - next year
#
# RegressionDataSet.new takes two parameters, data and features. Only send one
# or the other unless data is an array of arrays.
##
"""
Lpr.d "Creating new RegressionDataSet for year-schedule-retorfitted deltas"
scheduleDeltasDataSet = RegressionDataSet.new false, [:alias, :year, :baseCost, :retrofitted].concat((1981...2013).map{|year| 
	rgRetrofittedGrouping.keys.map{|scheduleKey|
		[
			(scheduleKey.to_s + "-" + year.to_s + "-retrofitted").to_sym,
			(scheduleKey.to_s + "-" + year.to_s + "-original").to_sym
		]
	}
}).flatten
Lpr.d "Doing martix transform: That the right term?"
rgDataSet.each{|data|
	entry = {alias: data[:schedule], year: data[:year], baseCost: data[:cost], retrofitted: data[:retrofitted]}
	rgDataSet.each{|deltaData|
		retrofitted = deltaData[:retrofitted].downcase == "true" ? "retrofitted" : "original"
		entry[(deltaData[:schedule].to_s + "-" + deltaData[:year].to_s + "-" + retrofitted).to_sym] =  entry[:baseCost] - deltaData[:cost]
	}
	scheduleDeltasDataSet.push entry
}
Lpr.d "Writing schedule delta output file schedule_deltas.csv"
scheduleDeltasDataSet.toCSV "#{TMP_PATH}/schedule_deltas.csv"

Lpr.p """
##
# Create DPP data for unretrofitted Schedule-Climate scenarios.
#
# The first step is to get only the retrofit = 'FALSE' data. This can
# be done with either filterByFunction or select. These return a new 
# RegressionDataSet. Both methods take a lambda expression that
# takes one parameter. The hashedData of the rgDataSet is 
# iterated over and each hash passed to the method.
##
"""
Lpr.d "Extracting original state data from delta data set"
originalData = scheduleDeltasDataSet.select{|data| data[:retrofitted] == "false"}
Lpr.d "No. original:	#{originalData.length}"

Lpr.p """
##
# Removing unwanted features from the data set.
#
# There are two ways of doing this depending on your fancy. Either
# dropFeatures (takes array) or segregate (takes array of features + an optional Boolean to dropping on current).
# In both cases you need to know the features you want. We'll do this by simply
# iterating over the features and looking for 'original'. 
#
# dropFeatures vs segregate:
#	dropFeatures [<features] 	- inline drop on this rgDataSet
#	segregate [<features>]		- return new RegressionDataSet with features
#	segregate [<features>], true	- As previous and drop features from original 
#
# NOTES:
#	- RegressionDataSet.features property contains symbols. Convert to string if necessary
##
"""
Lpr.d "Dropping features related to original processes"
originalData.dropFeatures originalData.features.select{|feature| feature.to_s.match(/original/i)}
Lpr.d "Dumping data to original_only_deltas.csv"
originalData.toCSV "#{TMP_PATH}original_only_deltas.csv"

Lpr.p """
##
# Translate savings to discounted payback periods.
#
# Translate savings to constant-cashflow DPPs. 
#
# NOTES:
#	The feature identification method's a bit lazy. Just makes sure the feature isn't
#	retrofit but contains the word. Do whatever
##
"""
Lpr.d "Extract feature set"
targetFeatures = originalData.features.select{|feature| feature.to_s.match(/\d\d\d\d.*retrofit/i)}
Lpr.d "Applying DPP to deltas"
originalData.apply{|data| 
	targetFeatures.each{|feature| 
		data[feature] = RegressionDataSet::dpp RETROFIT_COST, data[feature], DPP_RATE
	}
}
Lpr.d "Dumping DPP data to geneva_retrofit_dpp.csv"
originalData.toCSV "#{TMP_PATH}geneva_retrofit_dpp.csv"

Lpr.p """
##
# Inject min/max/avg
#
# As with extracting the alias earlier, we're injecting new features.
##
"""
Lpr.d "Inject max value"
originalData.injectFeatureByFunction(:max){|data|
	targetFeatures.map{|feature| data[feature]}.max
}
Lpr.d "Inject min value"
originalData.injectFeatureByFunction(:min){|data|
	targetFeatures.map{|feature| data[feature]}.select{|val| val != -10}.min
}
Lpr.d "Inject average value"
originalData.injectFeatureByFunction(:avg){|data|
	sum 	= 0
	count	= 0
	targetFeatures.map{|feature| data[feature]}.select{|val|
		if val != -10
			count 	+= 1
			sum 	+=  val
		end
	}
	sum / count
}

Lpr.d "Export standard to with stats to average_dpp.csv"
originalData.toCSV "#{TMP_PATH}average_dpp.csv"

Lpr.p """
##
# Create stats table grouping each schedule 
#
# TODO: Dec 2019 - Create a method that does this automatically
##
"""
Lpr.d "Creating new RegressionDataSet for Schedule-Climate stats"
statsDataSet = RegressionDataSet.new false, [
	:year,
	"implicit-min", "implicit-max", "implicit-avg",
	"explicit-min", "explicit-max", "explicit-avg",
	"original-min", "original-max", "original-avg"
].map{|feature| feature.to_sym}
Lpr.d "Group data by schedules"
scheduleStatGroups = originalData.groupBy(:alias)
Lpr.d "Sort schedule group data sets"
scheduleStatGroups.each{|key, scheduleDataSet| scheduleDataSet.sort!{|a, b| a[:year] <=> b[:year]}}
Lpr.d "Populate stats data set"
(0...scheduleStatGroups[:original].length).each{|idx|
	
	statsDataSet.push({
		year: 			scheduleStatGroups[:original].hashedData[idx][:year],
		"original-min": scheduleStatGroups[:original].hashedData[idx][:min],
		"original-max": scheduleStatGroups[:original].hashedData[idx][:max],
		"original-avg": scheduleStatGroups[:original].hashedData[idx][:avg],
		"implicit-min": scheduleStatGroups[:implicit].hashedData[idx][:min],
		"implicit-max": scheduleStatGroups[:implicit].hashedData[idx][:max],
		"implicit-avg": scheduleStatGroups[:implicit].hashedData[idx][:avg],
		"explicit-min": scheduleStatGroups[:explicit].hashedData[idx][:min],
		"explicit-max": scheduleStatGroups[:explicit].hashedData[idx][:max],
		"explicit-avg": scheduleStatGroups[:explicit].hashedData[idx][:avg],
	})
}
Lpr.d "Exporting stats Schedule-Climate Min/Max/Avg data to schedule_stats.csv"
statsDataSet.toCSV "#{TMP_PATH}schedule_stats.csv"

