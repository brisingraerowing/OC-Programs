local ser = require("serialization")
local fs = require("filesystem")

local function serialize(o)
	return ser.serialize(o)
end

local function deserialize(o)
	return ser.unserialize(o)
end

local M = {}

M.store = {}

function M.set(k, v)
	M.store[k] = v
	return v
end

function M.get(k)
	return M.store[k]
end

function M.delete(k)
	M.store[k] = nil
	return nil
end

function M.exists(k)
	return M.store[k] ~= nil
end

function M.decr(k, amount)
	local value = M.store[k]
	amount = amount or 1
	
	if type(value) ~= "number" then
		error("Cannot decrement a non number")
	else
		value = value - amount
		M.store[k] = value
		return value
	end
end

function M.incr(k, amount)
	local value M.store[k]
	amount = amount or 1
	
	if type(value) ~= "number" then
		error("Cannot increment a non-number")
	else
		value = value + amount
		M.store[k] = value
		return value
	end
end

function M.load(file)
	if not fs.exists(file) then
		error("File does not exist")
	end
	
	local f = io.open(file, "r")
	M.store = deserialize(f:read("*a"))
	f:close()
	
end

function M.save(file)
	if not fs.exists(file) then
		error("File does not exist")
	end
	
	local f = io.open(file, "w")
	f:write(serialize(M.store))
	f:close()
end

return M