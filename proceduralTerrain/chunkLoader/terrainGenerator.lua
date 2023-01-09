local terrainGenerator = {}

local params = require(script.Parent.Parent:WaitForChild("parameters"))
local precision = 1000000

-- Using Quasiduck's FillWedge
-- Base function to generate terrain into the world.
function terrainGenerator.fillWedge(wedgeCFrame, wedgeSize, material)
	local terrain = workspace.Terrain
	local Zlen, Ylen = wedgeSize.Z, wedgeSize.Y
	local longerSide, shorterSide, isZlonger
	if Zlen > Ylen then
		longerSide, shorterSide, isZlonger = Zlen, Ylen, true
	else
		longerSide, shorterSide, isZlonger = Ylen, Zlen, false
	end

	local closestIntDivisor = math.max(1, math.floor(shorterSide/3))
	local closestQuotient = shorterSide/closestIntDivisor
	local scaledLength = closestQuotient*longerSide/shorterSide    
	local cornerPos = Vector3.new(0, -Ylen, Zlen)/2
	for i = 1, closestIntDivisor - 1 do
		local longest_baselen = (closestIntDivisor-i)*scaledLength
		local size, cf = Vector3.new(math.max(3, wedgeSize.X), closestQuotient, longest_baselen)
		if isZlonger then
			cf = wedgeCFrame:toWorldSpace(CFrame.new(cornerPos) + Vector3.new(0, (i-0.5)*closestQuotient, -longest_baselen/2))
		else
			cf = wedgeCFrame:toWorldSpace(CFrame.Angles(math.pi/2, 0, 0) + cornerPos + Vector3.new(0, longest_baselen/2, -(i-0.5)*closestQuotient))
		end
		terrain:FillBlock(cf, size, material)
	end
	local diagSize = Vector3.new(math.max(3, wedgeSize.X), closestQuotient*scaledLength/math.sqrt(closestQuotient^2 + scaledLength^2), math.sqrt(Zlen^2 + Ylen^2)) --Vector3.new(3, 3, math.sqrt(Zlen^2 + Ylen^2))
	local rv, bv = wedgeCFrame.RightVector, -(Zlen*wedgeCFrame.LookVector - Ylen*wedgeCFrame.UpVector).Unit
	local uv = bv:Cross(rv).Unit
	local diagPos = wedgeCFrame.p - uv*diagSize.Y/2
	local diagCf = CFrame.fromMatrix(diagPos, rv, uv, bv)
	terrain:FillBlock(diagCf, diagSize, material)
end

-- FIX - does not take into account rotation -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- The chunks are made up of many small triangles. This function gets the material (e.g. snow, grass, etc.) of a polygon given it's
-- position and orientation, which is given by roblox's CFrame. Altitude, angle, the parameters script, and some randomness are factored in.
function getMaterial(cf)
	local material = params.defaultMaterial
	
	local scale = params.scale.Y
	local orig = params.origin.Y
	local height = cf.Position.Y
	local yMin,yMax = orig,orig+scale
	local x,y,z = cf:ToOrientation()
	x,z = math.deg(x),math.deg(z)
	local slope = math.max(math.abs(90-math.abs(z)),math.abs(0-math.abs(x)))
	local heightPercentage = (height-yMin)/(yMax-yMin)
	
	local materialSettings = params.materialSettings
	for i = 1, #materialSettings do
		local heightMin,heightMax,heightRandomness,slopeMin,slopeMax,slopeRandomness,currentMaterial =
			materialSettings[i][1],materialSettings[i][2],materialSettings[i][3],
			materialSettings[i][4],materialSettings[i][5],materialSettings[i][6],materialSettings[i][7]
		if heightPercentage > heightMin+math.random(-heightRandomness*precision,heightRandomness*precision)/precision
			and heightPercentage < heightMax+math.random(-heightRandomness*precision,heightRandomness*precision)/precision then
			if slope > slopeMin+math.random(-slopeRandomness*precision,slopeRandomness*precision)/precision
				and slope < slopeMax+math.random(-slopeRandomness*precision,slopeRandomness*precision)/precision then
				
				material = currentMaterial
			end
		end
	end
	
	return material
end
-- WARNING! Large triangles may result in exceeding max Region3 area
-- Generates a water chunk between sea level and the altitude of the polygon for a terrain triangle, pretty self-explanatory.
function generateWater(a,b,c,d,delete)
	local scale = params.scale.Y
	local orig = params.origin.Y
	local yMin,yMax = orig,orig+scale
	local maxHeight = params.waterLevel[2]*(yMax-yMin)+orig
	local minHeight = math.min(a.Y,b.Y,c.Y,d.Y)+orig
	if minHeight < maxHeight then
		local xy1,xy2 = 
			Vector3.new(a.X,minHeight,a.Z),
			Vector3.new(d.X,maxHeight,d.Z)
		local region = Region3.new(xy1,xy2)
		if delete == true then
			workspace.Terrain:ReplaceMaterial(region:ExpandToGrid(4),4,Enum.Material.Water,Enum.Material.Air)
		else
		workspace.Terrain:ReplaceMaterial(region:ExpandToGrid(4),4,Enum.Material.Air,Enum.Material.Water)
		end
	end
end

-- An absolute amalgamation of spaghetti code, this monster parses the weights of the foliage groups and parameters, determines if foliage will spawn
-- via a weighted random selection, then spawns it in the correct location. Obviously, this should have been split up into multiple functions,
-- but I wasn't the best programmer back then.
function terrainGenerator.spawnFoliage(cf,material,noisePos,delete)
	local foliageFolder = workspace:FindFirstChild("foliageFolder")
	if delete == true then
		if foliageFolder == nil then
			return
		else
			for i, v in pairs(foliageFolder:GetChildren()) do
				if v.Name == noisePos.X .. "_" .. noisePos.Y then
					v:Destroy()
					return
				end
			end
		end
	else
		local scale = params.scale.Y
		local orig = params.origin.Y
		local height = cf.Position.Y
		local yMin,yMax = orig,orig+scale
		local x,y,z = cf:ToOrientation()
		x,z = math.deg(x),math.deg(z)
		local slope = math.max(math.abs(90-math.abs(z)),math.abs(0-math.abs(x)))
		local heightPercentage = (height-yMin)/(yMax-yMin)
		
		local pos = cf.Position
		local spawnChance = params.spawnChance
		local foliageSettings = params.foliageGenerationSettings
		-- Create folder
		if foliageFolder == nil then
			foliageFolder = Instance.new("Folder")
			foliageFolder.Name = "foliageFolder"
			foliageFolder.Parent = workspace
		end
		local chunkFolder = foliageFolder:FindFirstChild(noisePos.X .. "_" .. noisePos.Y) 
		
		for i = 1, #foliageSettings do
			local correctMaterial = false
			local materials = foliageSettings[i][7]
			if materials[1] == nil then 
				correctMaterial = true 
			elseif materials[1] == true then
				for j = 2, #materials do
					if materials[j] == material then
						correctMaterial = true
						break
					end
				end
			elseif materials[1] == false then
				correctMaterial = true
				for j = 2, #materials do
					if materials[j] == material then
						correctMaterial = false
						break
					end
				end
			end
			
			if correctMaterial == true then
				local heightMin,heightMax,heightRandomness,slopeMin,slopeMax,slopeRandomness =
					foliageSettings[i][1],foliageSettings[i][2],foliageSettings[i][3],
					foliageSettings[i][4],foliageSettings[i][5],foliageSettings[i][6]
				if heightPercentage > heightMin+math.random(-heightRandomness*precision,heightRandomness*precision)/precision
					and heightPercentage < heightMax+math.random(-heightRandomness*precision,heightRandomness*precision)/precision then
					if slope > slopeMin+math.random(-slopeRandomness*precision,slopeRandomness*precision)/precision
						and slope < slopeMax+math.random(-slopeRandomness*precision,slopeRandomness*precision)/precision then
						
						if chunkFolder == nil then
							chunkFolder = Instance.new("Folder")
							chunkFolder.Name = noisePos.X .. "_" .. noisePos.Y
							chunkFolder.Parent = foliageFolder
						end
						
						local foliageReferences = foliageSettings[i][9]
						local foliageArr = {}
						for i, v in pairs(foliageReferences:GetChildren()) do
							foliageArr[#foliageArr+1] = v
						end
						-- Get sum of weights, and get ranges for each piece of foliage so we know
						-- what the math.random picked
						local weightSum = 0
						local ranges = {}
						for j = 1, #foliageArr do
							local currentWeight = foliageArr[j]:FindFirstChild("weight")
							if currentWeight == nil then
							currentWeight = 1
							else
								if currentWeight:IsA("IntValue") then
									currentWeight = currentWeight.Value
								else
									currentWeight = 1
								end
							end
							local sum = weightSum + currentWeight
							ranges[#ranges+1] = {weightSum,sum}
							weightSum = sum
						end
						-- Determine which foliage to spawn
						local pick = math.random(0,weightSum/(spawnChance))
						local index
						for j = 1, #ranges,1 do
							if pick > ranges[j][1] and
								pick <= ranges[j][2] then
								index = j
								break
							end
						end
						if index == nil then return end
						-- Create the foliage
						local foliage = foliageArr[index]:Clone()
						local rot = foliageSettings[i][8]
						local heightOff = foliageArr[index]:FindFirstChild("heightOffset")
						if heightOff == nil then
							heightOff = 0
						else
							if heightOff:IsA("IntValue") then
								heightOff = heightOff.Value
							else
								heightOff = 0
							end
						end
						if chunkFolder == nil then
							foliage.Parent = foliageFolder
						else
							foliage.Parent = chunkFolder
						end
						foliage:SetPrimaryPartCFrame(CFrame.new(
							pos+Vector3.new(0,heightOff,0))
							* CFrame.fromEulerAnglesXYZ(
									math.rad(math.random(0,rot.X)), 
									math.rad(math.random(0,rot.Y)), 
									math.rad(math.random(0,rot.Z))))
						return foliage
					end
				end
			end
		end
	end
end
-- Must be right triangle only, and 'a' must be the vertex at the 90 degree angle
-- Creates a terrain triangle from a few coordinates using fillWedge(). Recycled from my rennovation of the 3d model to terrain plugin.
function terrainGenerator.drawVoxelPolygon(a,b,c,material)
	local p = (b+c)/2
	local up,ba = (b-a).unit,-(c-a).unit
	local ri = up:Cross(ba)
	local cf = 
		CFrame.new(p.x,p.y,p.z,  ri.x,up.x, ba.x,  ri.y,up.y, ba.y,  ri.z,up.z, ba.z)
	local size = Vector3.new(8,(b-a).Magnitude,(c-a).Magnitude)
	if material == nil then
		material = getMaterial(cf)
	end
	terrainGenerator.fillWedge(cf,size,material)
	return cf, material
end

local res = params.resolution
local orig = params.origin
local scale = params.scale
local rot = params.rotation
-- Generates a chunk of terrain by subdividing the area into a grid, then filling it in with terrain triangles.
function terrainGenerator.generate(noise,noisePos,delete)
	local pos = orig+Vector3.new(
		noisePos.X*res*scale.X, 0,
		noisePos.Y*res*scale.Z)
	for i = 1, #noise-1 do
		for j = 1, #noise[1]-1 do
			-- math stuff
			local a = Vector3.new(
				(i-1)*scale.X+pos.X,
				noise[i][j]*scale.Y+pos.Y,
				(j-1)*scale.Z+pos.Z)
			local b = Vector3.new(
				i*scale.X+pos.X,
				noise[i+1][j]*scale.Y+pos.Y,
				(j-1)*scale.Z+pos.Z)
			local c = Vector3.new(
				(i-1)*scale.X+pos.X,
				noise[i][j+1]*scale.Y+pos.Y,
				j*scale.Z+pos.Z)
			local d = Vector3.new(
				i*scale.X+pos.X,
				noise[i+1][j+1]*scale.Y+pos.Y,
				j*scale.Z+pos.Z)	
			local rotCF = CFrame.Angles(math.rad(rot.X),math.rad(rot.Y),math.rad(rot.Z))
			a = rotCF*a
			b = rotCF*b
			c = rotCF*c
			d = rotCF*d
			local material
			if delete == true then
				material = Enum.Material.Air
			end
			-- generate terrain triangles
			local cf1, material1 = terrainGenerator.drawVoxelPolygon(a,b,c,material)
			local cf2, material2 = terrainGenerator.drawVoxelPolygon(d,b,c,material)
			-- spawn foliage
			terrainGenerator.spawnFoliage(cf1,material1,noisePos,delete)
			terrainGenerator.spawnFoliage(cf2,material2,noisePos,delete)
			-- maybe spawn water
			if params.waterLevel[1] == true then
				generateWater(a,b,c,d,delete)
			end
		end
	end
end

return terrainGenerator
