local shell = require("shell")
local component = require("component")

local args, opts = shell.parse(...)

if #args < 2 then
  io.stderr:write("ERROR: Not enough arguments")
  io.stderr:write("Usage: docdump <component name> <output file>")
  return
end

local componentName = args[1]
local outputFile = io.open(args[2], "w")

local proxy = component.getPrimary(componentName)

outputFile:write(componentName .. " = {}\n")
outputFile:write(componentName .. ".type = \"" .. componentName .. "\"\n")
outputFile:write(componentName .. ".address = \"00000000-0000-0000-0000-000000000000\"\n")
outputFile:write(componentName .. ".slot = 0\n\n")

for k, v in pairs(proxy) do

  if type(v) == "function" then

    

  elseif type(v) == "table" then

  elseif k == "type" or k == "address" or k == "slot"
    -- Handled above
  else
    io.stderr:write("ERROR: Could not process entry '" .. tostring(k) .. "' of type '" .. type(v) .. "'.")
    io.stderr:write("This is a bug. Please report this to the author on Github.")
  end

end