local config = nil
local colors = require("colors")
local sides = require("sides")
local component = require("component")
local event = require("event")
local sensor = component.sensor

local suspend = false

local function fluidWanted(data)
  return config.fluids[data.moofluids.fluid.name] ~= nil
end

local function onAccept()

end

-- Workaround for OpenComputers issue #1385
-- This will be removed when the fix in build 71 gets released.
-- Taken from https://gist.github.com/Talon24/71221bc026ea72d8245a830bc6785317
-- Has slight modifications to allow using more than one redstone IO system
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
    if lastChannels[address] == nil then
      lastChannels[address] = {}
    end
    if lastChannels[address][side] == nil then
        lastChannels[address][side] = Channels --to allow different bundled nets on each side
    end
    for k,v in pairs(lastChannels[address][side]) do
        if v ~= Channels[k] then
            channelChanged = k
            oldval = v
            newval = Channels[k]
        end
        Bundle = Bundle or (Channels[k]~=0) or (v~=0)
    end
    lastChannels[address][side] = Channels
    if Bundle then
        return channelChanged, oldval, newval
    else
        return -1, old, new -- minus one implies there is no channel
    end
end

local function logGeneral(msg)

end

local function logCow(data)

end

local function checkFluidCow()

  if suspend then return end

  local x, z

  if config.general.direction_from_sensor == "north" then
    x = 0
    z = -config.general.distance_from_sensor
  elseif config.general.direction_from_sensor == "east" then
    x = config.general.distance_from_sensor
    z = 0
  elseif config.general.direction_from_sensor == "west" then
    x = -config.general.distance_from_sensor
    z = 0
  elseif config.general.direction_from_sensor == "south" then
    x = 0
    z = config.general.distance_from_sensor
  else
    logGeneral("Invalid direction specified.")
    error("MooFluids Sorter: Invalid Direction Specified")
  end

  local data = sensor.searchEntities(x, 0, z, x, 0, z)
  if #data > 1 then
    logGeneral("More than one entity in analyzer area!")
    error("MooFluids Sorter: More than one entity in analyzer area!")
  end

  local entity = data[1]

  if entity.type == "neutral" and entity.moofluids ~= nil then

    if fluidWanted(entity) then

    else

    end

  else

    logGeneral("Invalid entity in analyzer area!")
    error("Invalid entity in analyzer area!")

  end

end

local function onRedstoneChanged(name, address, side, oldValue, newValue)

  if address == config.redstone.check_trigger.address and side == sides[config.redstone.check_trigger.side] then

    local chnl, old, new = channelUpdated(address, side, oldValue, newValue)

    if chnl = colors[config.redstone.check_trigger.color] then

      if new > 0 then
        checkFluidCow()
      end

    end

  elseif address == config.redstone.suspend.address and side == sides[config.redstone.suspend.side] then

    local chnl, old, new = channelUpdated(address, side, oldValue, newValue)

    if chnl = colors[config.redstone.suspend.color] then

      suspend = new > 0

    end

  end

end

function start()
  config = dofile("/etc/fluid_cows.cfg")
  -- Initialize the redstone stuff
  channelUpdated(config.redstone.check_trigger.address, sides[config.redstone.check_trigger.side], 0, 0)
  channelUpdated(config.redstone.suspend.address, sides[config.redstone.suspend.side], 0, 0)
  event.listen("redstone_modified", onRedstoneChanged)

end

function stop()

end
