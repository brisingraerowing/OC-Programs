local component = require("component")
local sides = require("sides")
local event = require("event")
local gryphonlib = require("gryphonlib")
local ini = require("inifile")
local fs = require("filesystem")
local computer = require("computer")

local function setup_motion_sensor(address)
	component.proxy(address).setSensitivity(0.2)
end

local config = nil

local function tosides(value)
	return sides[value] or sides.top
end

local function get_user_list(value)
	return gryphonlib.split_string(" ", value)
end

local function is_config_file(path)
	return path:match("^.+(%..+)$") == ".cfg" and fs.exists(path) and not fs.isDirectory(path) and not fs.isLink(path) -- We don't allow links for security reasons.
end

local function load_proxdoor_d_config(tbl, path)
	
	local tmp = ini.parse(path)
	
	tbl[tmp.addresses.motion_sensor] = {
		general = {
			name = tmp.general.name,
			range = tonumber(tmp.general.range),
			side = tosides(tmp.general.side),
			open_time = tonumber(tmp.general.open_time),
			inverted = gryphonlib.toboolean(tmp.general.inverted)
		},
		addresses = {
			redstone = component.proxy(tmp.addresses.redstone)
		},
		users = {
			user_list = get_user_list(tmp.users.user_list),
			is_blacklist = gryphonlib.toboolean(tmp.users.is_blacklist),
			allow_all = gryphonlib.toboolean(tmp.users.allow_all)
		}
	}
	
end

local function load_config()

	local tmp = ini.parse("/etc/proxdoor.cfg")
	
	config = {
		general = {
			event_on_entity_allowed = gryphonlib.toboolean(tmp.general.event_on_entity_allowed),
			event_on_entity_denied = gryphonlib.toboolean(tmp.general.event_on_entity_denied)
		},
		logging = {
			log_file_path = tmp.logging.log_file_path,
			general_log_file_name = tmp.logging.general_log_file_name,
			access_log_file_name = tmp.logging.access_log_file_name,
			general_log_enabled = gryphonlib.toboolean(tmp.logging.general_log_enabled),
			access_log_enabled = gryphonlib.toboolean(tmp.logging.access_log_enabled)
		},
		doors = {}
	}
	
	for path in fs.list(tmp.general.config_dir) don
		if is_config_file(path) then
			load_proxdoor_d_config(config.doors, path)
		end
	end

end

local function ensure_log_dir_exists()
	if not fs.exists(config.logging.log_file_path) then
		fs.makeDirectory(config.logging.log_file_path)
	end
end

local function log_general(msg)
	if config.logging.general_log_enabled then
		local file = assert(io.open(fs.concat(config.logging.log_file_path, config.logging.general_log_file_name), "a"), "Failed to open general log file.")
		file:write("[" .. os.date() .. "] : " .. msg)
		file:close()
	end
end

local function log_access(door, entity, perm)
	if config.logging.access_log_enabled then
		local file = assert(io.open(fs.concat(config.logging.log_file_path, config.logging.access_log_file_name), "a"), "Failed to open access log file.")
		file:write("[" .. os.date() .. "] Access Attempt. Door: " .. door .. " | Entity: " .. entity .. " | Permission: " .. perm)
		file:close()
	end
end

local function raise_proxdoor_access(door, entity, allowed)
	computer.pushSignal("proxdoor_access", door, entity, allowed)
end

local function on_entity_allowed(door, entity)
	if config.general.event_on_entity_allowed then
		raise_proxdoor_access(door, entity, true)
	end
end

local function on_entity_denied(door, entity)
	if config.general.event_on_entity_denied then
		raise_proxdoor_access(door, entity, false)
	end
end

local function is_in_range(range, x, y, z)
	local abs = math.abs
	return abs(x) <= range and abs(y) <= range and abs(z) <= range
end

local function is_allowed(cfg, entity)
	return cfg.allow_all or cfg.user_list[entity] or (cfg.is_blacklist and cfg.user_list[entity] == nil)
end

local function toggle_redstone(dev, side)
	if dev.getOutput(side) >= 1 then
		dev.setOutput(side, 0)
	else
		dev.setOutput(side, 15)
	end
end

local function motion_event(address, x, y, z, entity)

	local tmp = config.doors[address]
	
	if tmp ~= nil then
		
		if is_in_range(tmp.general.range, x, y, z) then
		
			if is_allowed(tmp.users, entity) then
				log_access(tmp.general.name, entity, "Allowed")
				on_entity_allowed(tmp.general.name, entity)
				toggle_redstone(tmp.addresses.redstone, tmp.general.side)
				os.sleep(tmp.general.open_time)
				toggle_redstone(tmp.addresses.redstone, tmp.general.side)
			else
				on_entity_denied(tmp.general.name, entity)
				log_access(tmp.general.name, entity, "Denied")
			end
		
		end
		
	end

end

function start()

	load_config()
	ensure_log_dir_exists()
	
	log_general("Initializing Proximity Door Daemon")
	
	log_general("Initializing doors")
	
	for _, v in pairs(config.doors) do
		if v.general.inverted then
			v.addresses.redstone.setOutput(v.general.side, 15)
		end
	end
	
	log_general("Doors initialized")
	
	log_general("Initializing event listeners")
	
	event.listen("motion", motion_event)
	
	log_general("Event listeners initialized")
	
	log_general("Proximity Door Daemon started")

end

function stop()

	log_general("Terminating Proximity Door Daemon")

	log_general("Terminating event listeners")
	
	event.ignore("motion", motion_event)
	
	log_access("Event listeners terminated")
	
	log_access("Closing all doors")
	
	for _, v in pairs(config.doors) do
		v.addresses.redstone.setOutput(v.general.side, 0)
	end
	
	log_access("All doors closed")
	
	log_general("Proximity Door Daemon stopped")
	
end