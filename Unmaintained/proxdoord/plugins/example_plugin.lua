-- Example Plugin for the Proximity Door Daemon

local n = require("note")

local M = {
	_NAME = "Example Plugin", -- The name of the plugin. Required.
	_AUTHOR = "Brisingr Aerowing", -- The author of the plugin. Required.
	_DESCRIPTION = "A simple example plugin", -- Short description of the plugin. Optional.
	_LICENSE = "CC0" -- The license of the plugin. Optional.
	-- Add any other fields you wish.
}

-- Called upon plugin loading. Required.
function M.init()
	
end

-- Called when the daemon is stopped. Required.
function M.shutdown()

end

-- Called when a access attempt is made. Required.
-- Parameters:
-- * door - The name of the door that triggered the attempt
-- * entity - The name of the entity that triggered the attempt
-- * allowed - Whether the entity was in the list of allowed entities
function M.entityAccess(door, entity, allowed)
	if allowed then
		n.play("A#5", 5)
	else
		n.play("A#0", 5)
	end
	return nil -- True allows the entity, false denies it, and nil simply performs the default action (as specified by allowed)
end

return M