--[[

  securityd.lua - Security server daemon for the OpenSecurity-Based door security system
  Author: Brisingr Aerowing
  Notes: Based on DustPuppy's security system

]]

local component = require("component")
local event = require("event")
local modem = component.modem
local ser = require("serialization")
local util = require("securelib")
local fs = require("filesystem")


local config = dofile("/etc/securityd.cfg")

local general_log_file = fs.concat(config.logging.log_file_path, config.logging.general_log_name)
local access_log_file = fs.concat(config.logging.log_file_path, config.logging.access_log_name)
local network_port = config.general.network_port
local crypt_key = config.general.crypt_key

local user_database_file = fs.concat(config.databases.database_path, config.databases.user_database_name)
local doors_database_file = fs.concat(config.databases.database_path, config.databases.doors_database_name)

local user_db = util.loadTable(user_database_file)
local doors_db = util.loadTable(doors_database_file)

if user_db = nil then
  user_db = {}
end
if doors_db = nil then
  doors_db = {}
end

local command_table = {

  ["updateuser"] = function(data, from, port)

      user_db = ser.unserialize(data)

      util.saveTable(user_db, user_database_file)

  end,

  ["setlevel"] = function(data, from, port)
    door_db[from] = data

    util.saveTable(door_db, doors_database_file)
  end,

  ["checkuser"] = function(data, from, port)

    local cu, isBlocked, level = checkUser(data)

    logAccess(data, isBlocked, level, from)

    if cu then

      if isBlocked then

        data = util.crypt("false", crypt_key)
        logGeneral("Access: Blocked")
        modem.send(from, port, data)

      else

        local cl = checkLevel(from)

        if cl > level then
          data = crypt("false", crypt_key)
          logGeneral("Access: Level Too Low")
          modem.send(from, port, data)
        else
          data = crypt("true", crypt_key)
          logGeneral("Access: OK")
          modem.send(from, port, data)
        end

      end

    end

  end

}

local commandNotFound(data, from, port)
  logGeneral("Error: Command not found")
  data = crypt("false", crypt_key)
  modem.send(from, port, data)
end

-- Local Functions (Logging, etc)

local function logGeneral(msg)

  local file = io.open(general_log_file, "a")

  file:write("[", os.date(), "] : ", msg, "\n")

  file:close()

end

local function logAccess(user, isBlocked, level, door_address)

  local file = io.open(access_log_file, "a")

  file:write("Access Attempt on ", os.date(), " : User = ", user, " : Is Blocked = ", isBlocked, " : Level = ", level, " : Door Address = ", door_address, "\n" )

  file:close()

end

local function checkUser(user)

  for _, v in pairs(user_db) do
    if v.name == user then
      return true, v.blocked, tonumber(v.level)
    end
  end

  return false

end

local function checkLevel(id)

  for k, v in pairs(door_db) do
    if k == id then
      return tonumber(v)
    end
  end

  return -1

end


local function modemEventHandler(x1, x2, from, port, x3, command, msg)

local data = util.crypt(msg, crypt_key, true)

logGeneral("Command Received : From " .. from .. " : Port " .. port .. " : Command " .. command)

local commandHandler = command_table[command] or commandNotFound

commandHandler(data, from, port)

end

local function ensurePaths()

  if not fs.isDirectory(config.databases.database_path) then
    fs.makeDirectory(config.databases.database_path)
  end
  if not fs.isDirectory(config.logging.log_file_path) then
    fs.makeDirectory(config.logging.log_file_path)
  end

end

-- End Local Functions


function start()

  ensurePaths()
  logGeneral("Initializing security daemon")
  logGeneral("Installing event handlers")
  event.listen("modem_message", modemEventHandler)
  logGeneral("Event Handlers Installed")
  if not modem.isOpen(network_port) then
    moden.open(network_port)
  end
  logGeneral("Initialization complete")

end

function stop()

  logGeneral("Stopping security daemon")
  event.ignore("modem_message", modemEventHandler)
  logGeneral("Security daemon stopped")

end