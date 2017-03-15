local tankutils = {}

local component = require("component")

-- Copied from Gryphonlib
local function iif(condition, true_value, false_value)
	if condition then return true_value else return false_value end
end

--[[
	Gets the readable name of the fluid in the tank specified by address
	
	Parameters:
	
	* address - Either the UUID address of a tank controller or an instance of the tank_controller component
	* side - The side the tank is on.
	
	Returns: The readable name of the fluid, e.g. 'Water' or 'Lava'.
]]
function tankutils.getFluidReadableName(address, side)
	local controller = iif(type(address) == "string", component.proxy(address), address)
	if controller then
		if controller.type then
			if controller.type ~= "tank_controller" then
				error("Expected tank controller, got " .. controller.type)
			end
		else
			error("Invalid controller (not a component)")
		end
	else	
		error("Invalid address/controller")
	end
	local fluid = controller.getFluidInTank(side)
	return fluid.label
end

return tankutils