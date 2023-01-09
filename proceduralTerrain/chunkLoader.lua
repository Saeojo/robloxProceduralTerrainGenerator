local players = game:GetService("Players")

local perlinNoise = require(script:WaitForChild("heightmapGenerator"):WaitForChild("perlinNoise"))
local terrGenerator = require(script:WaitForChild("terrainGenerator"))
local params = require(script.Parent:WaitForChild("parameters"))

local res = params.resolution
local layers = params.layers
local scale = params.scale
local orig = params.origin
local rot = params.rotation
local chunkLD = params.chunkLoadDistance
local chunkULD = params.chunkUnloadDistance
local precision = 1000

-- These values contain "grid position", which in this case is the unit value that is used to
-- get the position in the game, and on the noise chart so each chunk can be placed perfectly in position.
local chunks = {}
local unloadedChunks = {
	Vector2.new(0,0)
}

function updateChunkArrs_Add(index)
	-- Reference chunk before it is removed
	local chunk = unloadedChunks[index]
	-- Update Arrs
	-- Remove index from unloadedChunks
	table.remove(unloadedChunks,index)
	-- Add to chunks
	chunks[#chunks+1] = chunk

	-- Add Adjacent Chunks to UnloadedChunks
	-- Get Adjacent Chunks
	local adj = {
		Vector2.new(chunk.X+1,chunk.Y),
		Vector2.new(chunk.X-1,chunk.Y),
		Vector2.new(chunk.X,chunk.Y+1),
		Vector2.new(chunk.X,chunk.Y-1)}
	-- Check validity of each chunk
	for i = 1, #adj do
		for j = 1, #chunks do
			if adj[i] == chunks[j] then
				adj[i] = nil
			end
		end
		for j = 1, #unloadedChunks do
			if adj[i] == unloadedChunks[j] then
				adj[i] = nil
			end
		end
		-- If valid, add to unloadedChunks
		if adj[i] ~= nil then 
			unloadedChunks[#unloadedChunks+1] = adj[i] 
		end
	end
end

function updateChunkArrs_Delete(index)
	local chunk = chunks[index]
	table.remove(chunks,index)
	local potentialChunkAdj = {
		Vector2.new(chunk.X+1,chunk.Y),
		Vector2.new(chunk.X-1,chunk.Y),
		Vector2.new(chunk.X,chunk.Y+1),
		Vector2.new(chunk.X,chunk.Y-1)}
	local chunkAdj = {}
	local unloadedChunkAdj = {}
	local chunkAdj_unloadedChunkAdj = {}
	for i = 1, #unloadedChunks do
		for j = 1, #potentialChunkAdj do
			if unloadedChunks[i] == potentialChunkAdj[j] then
				unloadedChunkAdj[#unloadedChunkAdj] = potentialChunkAdj[j]
			end
		end
	end
	-- For every chunk and potential adjacent chunk
	for i = 1, #chunks do
		for j = 1, #potentialChunkAdj do
			-- If a chunk is equal to the potential adjacent chunk
			if chunks[i] == potentialChunkAdj[j] then
				-- Add that chunk to adjacent chunks
				chunkAdj[#chunkAdj+1] = potentialChunkAdj[j]
				local c = chunkAdj[#chunkAdj]
				-- Then, get potential adjacent unloaded chunks
				local potentialUnloadedChunkAdj = {
					Vector2.new(c.X+1,c.Y),
					Vector2.new(c.X-1,c.Y),
					Vector2.new(c.X,c.Y+1),
					Vector2.new(c.X,c.Y-1)}
				-- For every potential unloaded chunk and unloaded chunk
				for k = 1, #potentialUnloadedChunkAdj do
					for l = 1, #unloadedChunks do
						-- If there is an unloaded chunk in the potential adjacent unloaded chunk then
						if potentialUnloadedChunkAdj[k] == unloadedChunks[l] then
							-- Check if it is already in the unloaded chunks adjacent to the adjacent chunks
							for a = 1, #chunkAdj_unloadedChunkAdj do
								if potentialUnloadedChunkAdj[k] == chunkAdj_unloadedChunkAdj[a] then
									potentialUnloadedChunkAdj[k] = nil
								end
							end
							if potentialUnloadedChunkAdj[k] ~= nil then
								-- And finally assign the variable
								chunkAdj_unloadedChunkAdj[#chunkAdj_unloadedChunkAdj] = potentialUnloadedChunkAdj[k]
							end
						end
					end
				end
			end
		end
	end
	for i = 1, #chunkAdj_unloadedChunkAdj do
		for j = 1, #unloadedChunkAdj do
			if chunkAdj_unloadedChunkAdj[i] ~= unloadedChunkAdj[j] then
				for k = 1, #unloadedChunks do
					if unloadedChunks[k] == unloadedChunkAdj[j] then
						table.remove(unloadedChunks[k])
					end
				end
			end
		end
	end
end

while true do
	-- For every player
	for i, v in pairs(players:GetChildren()) do
		v.CameraMaxZoomDistance = 999999
		local char = v.Character or v.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid")
		local playerPos = char.PrimaryPart.Position
		-- And for every unloaded chunk
		local remove = {}
		local min = 999999999999
		local chunk = nil
		local index = 0
		for j = 1, #unloadedChunks do
			local chunkPos = orig+Vector3.new(
				unloadedChunks[j].X*res*scale.X, 0,
				unloadedChunks[j].Y*res*scale.Z)
			local dist = (playerPos-Vector3.new(chunkPos.X,playerPos.Y,chunkPos.Z)).Magnitude
			if dist < min then
				chunk = unloadedChunks[j]
				min = dist
				index = j
			end
		end
		if chunk ~= nil then
			local noise = perlinNoise.getNoise(chunk.X,chunk.Y)
			terrGenerator.generate(noise,chunk)
			updateChunkArrs_Add(index)
			--break
		end
		for j = 1, #unloadedChunks do
			local chunkPos = orig+Vector3.new(
				unloadedChunks[j].X*res*scale.X, 0,
				unloadedChunks[j].Y*res*scale.Z)
			-- Check if the chunk is within rendering distance
			if (playerPos-Vector3.new(chunkPos.X,playerPos.Y,chunkPos.Z)).Magnitude < chunkLD then
				-- And render!
				local noise = perlinNoise.getNoise(unloadedChunks[j].X,unloadedChunks[j].Y)
				terrGenerator.generate(noise,unloadedChunks[j])
				updateChunkArrs_Add(j)
				break
			end
		end
		if params.enableUnloading == true then
			for j = 1, #chunks do
				local chunkPos = orig+Vector3.new(
					chunks[j].X*res*scale.X, 0,
					chunks[j].Y*res*scale.Z)
				if (playerPos-Vector3.new(chunkPos.X,playerPos.Y,chunkPos.Z)).Magnitude > chunkULD then
					-- And render!
					local noise = perlinNoise.getNoise(chunks[j].X,chunks[j].Y)
					terrGenerator.generate(noise,chunks[j],true)
					updateChunkArrs_Delete(j)
					break
				end
			end
		end
	end
	-- So the loop doesn't explode
	wait()
end