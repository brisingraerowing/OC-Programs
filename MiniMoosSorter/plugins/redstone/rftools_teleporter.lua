local config = nil
local methods = nil

local plugin_name = "RFTools Teleporter Plugin"

local dialing_device = nil
local transmitter_location = nil

local function log(msg)
  methods.log(plugin_name, msg)
end

local function initialize(plugin_config)

  config = plugin_config.config
  methods = plugin_config.methods

  log("Loading config data")
  loadConfig()
  log("Registering events")
  registerEvents()
  log("Initialized")
end

local function shutdown()

  log("Unregistering events")
  unregisterEvents()

end

local function getPluginInfo()
  return {
    version = "1.0.0",
    author = "Brisingr Aerowing",
    name = plugin_name,
    license = "LGPL",
    copyright = "Copyright (c) Brisingr Aerowing 2018"
  }
end

local function loadConfig()

end

local function dial(x, y, z)

end