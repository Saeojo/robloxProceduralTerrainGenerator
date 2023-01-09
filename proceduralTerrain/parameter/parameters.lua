local params = {}

-- Misc

params.enableWarningMessages = true

-- Chunk Loading Settings

params.enableUnloading = true
-- Distance for player to load/unload chunks
params.chunkLoadDistance = 2000
params.chunkUnloadDistance = params.chunkLoadDistance
	
-- Heightmap Settings
-- Perlin Noise Setting
	local function rand()
		return math.random(-1000,1000)
	end
	params.resolution = 40
	params.layers = {
		{4,4096,rand(),rand()},
		{2,2048,rand(),rand()},
		{1,1024,rand(),rand()},
		{0.5,512,rand(),rand()},
		{0.125,256,rand(),rand()},
		{0.0625,128,rand(),rand()},
		{0.03125,64,rand(),rand()},
		{0.015625,32,rand(),rand()},
		{0.0078125,16,rand(),rand()},
		{0.00390625,8,rand(),rand()},
		{0.001953125,4,rand(),rand()},
		{0.0009765625,2,rand(),rand()}
	}
-- Hydraulic Erosion Settings
		
-- Terrain Generation Settings

-- Terrain Settings
params.scale = Vector3.new(5,7500,5)
params.origin = Vector3.new(0,0,0)
params.rotation = Vector3.new(0,0,0)
-- Foliage Settings
params.spawnChance = 0.01
params.foliageGenerationSettings = {
	{
		0.72,0.8,0.04,
		0,40,5,
		{false, Enum.Material.Sand, Enum.Material.Slate, Enum.Material.Snow, Enum.Material.Rock,Enum.Material.Mud},
		Vector3.new(0,360,0),
		script:WaitForChild("foliageGroup1")
	},
	{
		0.72,0.8,0.01,
		35,45,5,
		{},
		Vector3.new(0,360,0),
		script:WaitForChild("foliageGroup2")
	}
}
-- Material Settings
params.defaultMaterial = Enum.Material.Grass
params.waterLevel = {
	true,
	0.71
}
params.materialSettings = {
	{
		0,0.72,0.01,
		0,35,5,
		Enum.Material.Sand
	},
	{
		0,0.72,0.01,
		35,90,5,
		Enum.Material.Slate
	},
	{
		0.72,0.8,0,
		0,35,5,
		Enum.Material.Grass
	},
	{
		0.72,0.8,0,
		35,90,5,
		Enum.Material.Mud
	},
	{
		0.85,5,0.05,
		0,35,5,
		Enum.Material.Snow
	},
	{
		0.85,5,0.05,
		35,90,5,
		Enum.Material.Rock
	}
}

return params
