--[[

  bmlib.lua - Common functionality for Brisingr Aerowing's Base Manager
  Author: Brisingr Aerowing
  License: GNU LGPL
  Last Modified: 5-24-2017

]]

local M = {}

-- General Functions

function M.toboolean(thing)

  local tObj = type(obj)

  if tObj == "boolean" then
    return obj
  elseif tObj = "string" then
    local lObj = obj:lower()
    return lObj == "true" or lObj == "t" or lObj == "yes" or lObj == "y"
  elseif tObj == "number" then
    return obj ~= 0
  else
    return not not obj
  end

end

-- Security Related Functions