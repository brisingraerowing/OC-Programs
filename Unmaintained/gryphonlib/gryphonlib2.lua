local comp = require("computer")
local fs = require("filesystem")
local component = require("component")
local term = require("term")
local internet = require("internet")

local M = {}
local Vars = {}

Vars.has_internet = component.isAvailable("internet")

local version = "2.0.0.0"
local name = "GryphonLib"
local description = "Common utility code for Brisingr Aerowing's programs"

local gpu = component.isAvailable("gpu") and component.gpu or { getResolution = function() return 80, 24 end, set = function(x, y, value) end }

M.text = {}
M.text.format  = {}
M.util = {}
M.io = {}
M.error = {}
M.internet = {}

-- General

function M.version()
  return version
end

function M.name()
  return name
end

function M.description()
  return description
end

-- Misc utility functions

function M.util.toboolean(obj)
  local tObj = type(obj)

	if tObj == "boolean" then
		return obj
	elseif tObj == "string" then
		local lObj = obj:lower()
		return lObj == "true" or lObj == "t" or lObj == "yes" or lObj == "y"
	elseif tObj == "number" then
		return obj ~= 0
	else
		return not not obj
	end
end

function M.util.iif(condition, true_value, false_value)
  if condition then return true_value else return false_value end
end

-- IO functions

function M.io.read(path)
  local file = io.open(path)
  if not file then return nil, "Error opening file" end
  local data = file:read("*all")
  file:close()
  return data
end

function M.io.write(path, data, overwrite)
  local file = assert(io.open(path, overwrite and "w" or "a"))
  file:write(data)
  file:close()
  return true
end

-- Error functions

function M.error.notice(data, ...)
  io.stderr:write(string.format(data .. "\n", table.unpack(arg)))
  comp.beep()
end

-- Text related functions

function M.text.format.justify(a ,b , c) -- Taken from Kodos' Lib
    if c == "center" then
        local str = b
        local maxX, maxY = gpu.getResolution()
        local start = ((maxX - #str) / 2) + 1
        gpu.set(start, a, str)
    elseif c == "right" then
        local str = b
        local maxX, maxY = gpu.getResolution()
        local start = (maxX - #str) + 1
        gpu.set(start, a, str)
    elseif c == "left" then
        local str = b
        gpu.set(1, a, str)
    end
end

function M.text.hline(y, char)
    local maxX, maxY = gpu.getResolution()
    local char = char or "-"
    local chara = ""
    for i = 1, maxX do
        chara = chara..char
    end
    gpu.set(1, y, chara)
end

function M.text.split(sep, str, maxSplit, isregex)
  assert(sep ~= '')
	assert(maxSplit == nil or maxSplit >= 1)

	local aRecord = {}

	if str:len() > 0 then
		local bPlain = not isregex
		maxSplit = maxSplit or -1

		local nField, nStart = 1, 1
		local nFirst,nLast = str:find(sep, nStart, bPlain)
		while nFirst and maxSplit ~= 0 do
			aRecord[nField] = str:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = str:find(sep, nStart, bPlain)
			maxSplit = maxSplit-1
		end
		aRecord[nField] = str:sub(nStart)
	end

	return aRecord
end

function M.text.starts(str, value)
  return string.sub(str, 1, string.len(value)) == value
end

function M.text.ends(str, value)
  return value == "" or string.sub(str, -string.len(value)) == value
end

-- Internet functions

function M.internet.isAvailable()
  return Vars.has_internet
end

function M.internet.downloadRaw(url)
  assert(M.internet.isAvailable())

  local sContent = ""
  local result, response = pcall(internet.request, url)

  if not result then
    return nil
  end
  for chunk in response do
    sContent = sContent..chunk
  end
  return sContent
end

