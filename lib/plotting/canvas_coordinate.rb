class CanvasCoordinate
	attr_reader :x, :y
	def initialize x, y
		@x	= x
		@y	= y
	end
	def offset x, y
		@x += x
		@y += y
	end
	def to_s
		"x: #{@x}\ty: #{@y}"
	end
end