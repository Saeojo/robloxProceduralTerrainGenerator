local _2dArrLib = {}

function _2dArrLib.getArrXY(array)
	return #array, #array[1]
end

function _2dArrLib.create(x,y,default)
	local array = {}
	for i = 1, x do
		array[i] = {}
		for j = 1, y do
			array[i][j] = default
		end
	end
	return array
end

function _2dArrLib.addArrs(array,array1)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] += array1[i][j]
		end
	end
	return array
end

function _2dArrLib.subtArrs(array,array1)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] -= array1[i][j]
		end
	end
	return array
end

function _2dArrLib.divArrs(array,array1)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] /= array1[i][j]
		end
	end
	return array
end

function _2dArrLib.multArrs(array,array1)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] *= array1[i][j]
		end
	end
	return array
end

function _2dArrLib.addArrNum(array,num)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] += num
		end
	end
	return array
end

function _2dArrLib.subtArrNum(array,num)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] -= num
		end
	end
	return array
end

function _2dArrLib.divArrNum(array,num)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] /= num
		end
	end
	return array
end

function _2dArrLib.multArrNum(array,num)
	local x,y = _2dArrLib.getArrXY(array)
	for i = 1, x do
		for j = 1, y do
			array[i][j] *= num
		end
	end
	return array
end

return _2dArrLib