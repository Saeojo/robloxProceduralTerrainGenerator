local perlinNoise = {}

local _2dArrLib = require(script.Parent:WaitForChild("2dArrayLib"))
local params = require(script.Parent.Parent.Parent:WaitForChild("parameters"))

function perlinNoise.getNoise(xPos,yPos)
	local res = params.resolution+1
	local function generate2d(samplesPerInt,x,y)
		local function f(num)
			return -2*math.abs(num-0.5)+1
		end
		local arr = _2dArrLib.create(res,res,0)
		for i = 1, res do
			for j = 1, res do
				local increment = 1/samplesPerInt
				arr[i][j] = f((math.noise((increment*i)+x,(increment*j)+y)+1)/2)
			end
		end	
		return arr
	end
	local layers = params.layers
	local sum = _2dArrLib.create(res,res,0)
	local weightSum = 0
	for i = 1, #layers do
		local weight,samplesPerInt,x,y = layers[i][1],layers[i][2],layers[i][3],layers[i][4]
			x,y = x+(res-1)*(xPos/samplesPerInt),y+(res-1)*(yPos/samplesPerInt)
		sum = _2dArrLib.addArrs(sum,_2dArrLib.multArrNum(generate2d(samplesPerInt,x,y),weight))
		weightSum += weight
	end
	return _2dArrLib.divArrNum(sum,weightSum)
end

return perlinNoise