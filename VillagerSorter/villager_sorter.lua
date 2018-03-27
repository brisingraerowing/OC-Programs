local component = require("component")
local fs = require("filesystem")

local config = dofile("/etc/villager_sorter.cfg")

local villagerLogFile = fs.concat(config.logging.log_directory, config.logging.villager_log_name)
local generalLogFile = fs.concat(config.logging.log_directory, config.logging.general_log_name)

local function checkDirs()
  if not fs.exists(config.logging.log_directory) then
    if not fs.makeDirectory(config.logging.log_directory) then
      error("FATAL: Could not create log directory")
    end
  end
end

local function logVillager(villagerId, villagerCareer, status)

end

local function logGeneral(msg)

end

local function checkVillager()

end

-- Workaround for OpenComputers issue #1385
-- Taken from https://gist.github.com/Talon24/71221bc026ea72d8245a830bc6785317
--Use this function after receiving redstone_modified signal
--Checks if the modification was received over bounded cable/EnderIO conduit
--3rd and 4th parameter are used as fallback if connection is not bounded (or nothing there)
--returns channel on which update was made, old value and new value
local function channelUpdated(address, side, old, new) --values from signal
    local r = component.proxy(address)
    local channelChanged, oldval, newval, Bundle= nil, nil, nil, false
    Channels = r.getBundledInput(side)
    if lastChannels == nil then
        lastChannels = {}
    end
    if lastChannels[side] == nil then
        lastChannels[side] = Channels --to allow different bundled nets on each side
    end
    for k,v in pairs(lastChannels[side]) do
        if v ~= Channels[k] then
            channelChanged = k
            oldval = v
            newval = Channels[k]
        end
        Bundle = Bundle or (Channels[k]~=0) or (v~=0)
    end
    lastChannels[side] = Channels
    if Bundle then
        return channelChanged, oldval, newval
    else
        return -1, old, new -- minus one implies there is no channel
    end
end

local function onRedstoneChanged(address, side, oldValue, newValue)

end

