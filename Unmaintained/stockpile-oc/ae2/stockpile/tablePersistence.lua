local fs = require("filesystem")
local serialization = require("serialization")

local M = {}

function M.load(file)

  local loaded = nil

  if fs.exists(file) then
    local fh = io.open(file, "r")
    local s = fh:read("*a")
    loaded = serialization.unserialize(s)
    fh:close()
  end

  return loaded

end

function M.save(file, value)

  local fh = io.open(file, "w")

  fh:write(serialization.serialize(value))

  fh:close()

end

return M