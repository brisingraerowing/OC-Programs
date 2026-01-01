--[[
    tcutils.lua - Utilities for the Traffic Control mod's Traffic Light Card
    
    Author: Brisingr Aerowing
    Last Modified: 3-6-24
]]

local tccard = require("component").traffic_light_card

local M = {}

local indexToLight = {}
local nameToLight = {}

local lights = tccard.listBlockPos()

for i = 1, #lights do
    indexToLight[i] = lights[i]
end

---Sets the name of a particular light
---@param index number The index of the light to name
---@param name string The name of the light
---@param overwrite boolean True to overwrite the provided name if it already exists
---@return boolean True if success, False and a message otherwise
---@return string Error message, may be nil
function M.setLightName(index, name, overwrite)

    overwrite = overwrite or false

    if index == nil then
        return false, "No index provided"
    end

    if name == nil or name == "" then
        return false, "No name provided"
    end

    if type(index) ~= "number" then
        return false, "Index is not a number"
    end

    if type(name) ~= "string" then
        return false, "Name is not a string"
    end

    if nameToLight[name] ~= nil and not overwrite then
        return false, "Name already exists"
    end

    nameToLight[name] = indexToLight[index]

    return true

end

---Gets a list of all named lights
---@return table A list of all names
function M.getLightNames()
    local keys = {}
    for key, _ in pairs(nameToLight) do
        table.insert(keys, key)
    end
    return keys
end

---Clears the states of one or more lights
---@param id table|number|string Either a list of IDs / Names to clear, or a specific id / name
---@return boolean True if success, False and a message if failure
---@return string Error message if failure, may be nil
function M.clearStates(id)

    local pos = {}

    if type(id) == "table" then
            
        for itr = 1, #id do
            
            if type(id[itr]) == "number" then
                if id[itr] < 1 or id[itr] > #indexToLight then
                    return false, "Invalid index"
                end
                table.insert(pos, indexToLight[id[itr]])
            elseif type(id[itr]) == "string" then
                if nameToLight[id[itr]] == nil then
                    return false, "Invalid name"
                end
                table.insert(pos, nameToLight[id[itr]])
            end

        end

    elseif type(id) == "number" then
        table.insert(pos, indexToLight[id])
    elseif type(id) == "string" then
        table.insert(pos, nameToLight[id])
    else
        return false, "Invalid ID type, must be table, number or string"
    end

    if #pos == 0 then
        return false, "INTERNAL ERROR: could not get light positions"
    end

    for k, v in pairs(pos) do
        tccard.clearStates(v[1], v[2], v[3])
    end
    return true

end

---Sets the states of a singular light
---@param id number|string The ID or name of the light to set
---@param state table|string Either a list of states, or a singular state
---@param mode string The mode to set. Either 'flashing' or 'on'
---@param forceClear boolean Whether to initially clear the light's states
---@return boolean True if success, False and an error message if failure
---@return string Error message if failure, may be nil
function M.setLight(id, state, mode, forceClear)

    local s, f = false, false

    forceClear = forceClear or false

    if forceClear then
        M.clearStates(id)
    end

    local pos = nil

    if type(id) == "table" then
        return false, "ID cannot be a table. Use setLights to set multiple lights at once"
    elseif type(id) == "number" then
        pos = indexToLight[id]
    elseif type(id) == "string" then
        pos = nameToLight[id]
    else
        return false, "Invalid ID type, must be number or string"
    end

    if mode ~= nil then
        
        if string.lower(mode) == "flashing" then
            s = true
            f = true
        elseif string.lower(mode) == "on" then
            s = true
            f = false
        else
            s = false
            f = false
        end
    else
        s = false
        f = false
    end

    if type(state) == "table" then
        
        for _, v in pairs(state) do
            tccard.setState(pos[1], pos[2], pos[3], v, s, f)
        end

    elseif type(state) == "string" then
        tccard.setState(pos[1], pos[2], pos[3], state, s, f)
    else
        return false, "Invalid state type, must be table or string"
    end

    return true

end

---Sets the states of one or more lights
---@param id table|string|number Either a list of IDs / Names, or a singular ID / Name
---@param state table|string Either a list of states to set, or a singular state
---@param mode string The mode to set. Either 'flashing' or 'on'
---@param forceClear boolean Whether to initially clear the light's states
---@return boolean True if success, False and a list of error messages if failure
---@return table A list of errors that occurred while setting lights. May be nil
function M.setLights(id, state, mode, forceClear)

    local ret = true
    local msg = {}

    if type(id) == "table" then
        for _, v in pairs(id) do
            local a, b = M.setLight(v, state, mode, forceClear)
            if a == false then
                ret = false
                msg[#msg + 1] = b
            end
        end
    elseif type(id) == "number" or type(id) == "string" then
        local a, b = M.setLight(id, state, mode, forceClear)
        if a == false then
            ret = false
            msg[1] = b
        end
    end

    if ret then
        return true
    else
        return false, msg
    end

end

return M
