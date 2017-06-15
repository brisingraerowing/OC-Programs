--[[

  doord.lua - Door controller for the OpenSecurity-Based door security system
  Author: Brisingr Aerowing
  Notes: Based on DustPuppy's security system

]]

local component = require("component")
local event = require("event")
local ser = require("serialization")
local util = require("securelib")
local computer = component.computer
local door = component.os_door
local magReader = component.os_magreader
local modem = component.modem

local config = dofile("/etc/doord.cfg")

local crypt_key = config.general.crypt_key
local network_port = config.general.network_port
local access_level = config.general.access_level
local beep_on_allowed = config.general.beep_on_allowed
local open_time = config.general.open_time

local function splitString(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local function magdataHandler(x1, x2, user, str, uuid)

  local data = util.crypt(str, crypt_key, true)

  local tmpTable = splitString(data, " ")

  if not modem.isOpen(network_port) then
    modem.open(network_port)
  end

  data = util.crypt(tmpTable[3], crypt_key)

  modem.brodcast(network_port, "checkuser", data)

  local e, _, from, port, _, msg = event.pull(1, "modem_message")

  if e then

    data = util.crypt(msg, crypt_key, true)

    if data == "true" then
      if beep_on_allowed then
        computer.beep()
      end
      door.toggle()
      os.sleep(open_time)
      door.toggle()
    else
      computer.beep(20, 5)
      computer.beep(20, 1)
      computer.beep(20, 1)
      computer.beep(20, 5)
    end

  else
    -- Server timeout :(
    computer.beep(20, 1)
    computer.beep(20, 1)
    computer.beep(20, 1)
    computer.beep(20, 5)

  end

end

function start()

  event.listen("magData", magdataHandler)

end

function stop()
  event.ignore("magData", magdataHandler)
end