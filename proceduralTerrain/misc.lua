local misc = {}

local params = require(script.Parent:WaitForChild("parameters"))

function misc.warn(s) 
	if params.enableWarningMessages == true then
		print(s)
	end
end

return misc
