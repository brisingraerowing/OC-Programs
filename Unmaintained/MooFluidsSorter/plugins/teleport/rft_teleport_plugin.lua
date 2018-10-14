local ACCEPT = nil
local REJECT = nil

-- Called on initialization
-- config is the table specified in the configuration file
-- data is a table that contains constants and functions used in
-- interacting with the program (Read-Only)
local function init(config, data)
  ACCEPT = data.constants.ACCEPT
  REJECT = data.constants.REJECT
end

-- Called when the program is terminated normally
local function shutdown()

end

-- Called when a cow is accepted
local function onAccept(cowData)
  return ACCEPT
end

-- Called when a cow is rejected
local function onReject(cowData)
  return REJECT
end

-- Returns true if the plugin can handle the fluid
local function canHandle(fluid)

end

-- Returns true if the plugin is purely cosmetic (e.g. Fireworks when a cow is accepted)
-- Cosmetic plugins are not counted when checking if all fluids are handled
local function isCosmetic()
  return false
end

return {
  init = init,
  shutdown = shutdown,
  onAccept = onAccept,
  onReject = onReject,
  canHandle = canHandle,
  isCosmetic = isCosmetic
  -- Returns the used API version. Currently only the value 1 is supported.
  getApiVersion = function() return 1 end
}