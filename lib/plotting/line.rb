require "./lib/plotting/graph_object.rb"
class GraphLine < GraphObject
	def initialize startPoint, endPoint, colour = :yellow, patternChar="-", nodeChar="+"
		super startPoint, patternChar, colour
		@endPoint	= endPoint
		@nodeChar	= nodeChar
	end
	def coordinates
		deltaX 	= @startPoint.x - @endPoint.x
		deltaY 	= @startPoint.y - @endPoint.y
		maxDiff	= [deltaX.abs, deltaY.abs].max
		ratio	= deltaX == 0 ? 0 : deltaY .to_f / deltaX.to_f
		(0...maxDiff).map{|idx|
			x = (idx * ratio).round.to_i + deltaX
			CanvasCoordinate.new @startPoint.x + ((1+idx) * ratio).round, @startPoint.y + 1 + idx
		}	
	end
	def length
		((@startPoint.x - @endPoint.x) ** 2 + (@startPoint.y + @endPoint.y) ** 2) ** 0.5
	end
	def pixels
		deltaX 		= @startPoint.x - @endPoint.x
		deltaY 		= @startPoint.y - @endPoint.y
		xDirection	= deltaX != 0 ?  -deltaX / deltaX.abs : 1
		yDirection	= deltaY != 0 ?  deltaY / deltaY.abs : 1
		maxDiff		= [deltaX.abs, deltaY.abs].max
		ratio		= deltaX == 0 ? 0 : deltaY .to_f / deltaX.to_f
		if maxDiff == deltaX.abs
			canvasPixels = (0...maxDiff).map{|idx|
				increment = (deltaY.to_f / maxDiff*  idx)
				CanvasPixel.new(
					@startPoint.x + idx, 
					(@startPoint.y + increment * yDirection).round.to_i, 
					@patternChar,
					@colour
				)
			}
		else
			canvasPixels = (0...maxDiff).map{|idx|
				increment = (deltaX.to_f / maxDiff *  idx)
				CanvasPixel.new(
					(@startPoint.x + increment * xDirection).round.to_i,
					@startPoint.y + idx,  
					@patternChar
				)
			}
		end
		canvasPixels[0] = CanvasPixel.new(
			canvasPixels[0].column, 
			canvasPixels[0].row, 
			@nodeChar, 
			:yellow
		)
		canvasPixels[canvasPixels.length - 1]	= CanvasPixel.new(
			canvasPixels[canvasPixels.length - 1].column, 
			canvasPixels[canvasPixels.length - 1].row, 
			@nodeChar, 
			:yellow
			)
		canvasPixels
	end
	def to_s
		"Start:	#{@startPoint}\tColour: #{@colour}\nEnd:	#{@endPoint}\tSymbol:   #{@patternChar}"
	end
end