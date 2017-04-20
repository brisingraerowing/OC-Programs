--[[

  MapUtils - Utilities for using OpenComputers to control Adventure/Puzzle/etc maps.

  Author: Brisingr Aerowing
  License: GNU LGPL

]]

local debug = require("debug")
local vector = require("vector")

local function isnumber(thing)
  return type(thing) == "number" or (type(thing) == "string" and tonumber(thing) ~= nil)
end

local function isstring(thing)
  return type(thing) == "string"
end

local function iff(condition, true_value, false_value)

  if condition then
    return true_value
  else
    return false_value
  end

end

--[[

  Determines whether a player is within a specific cuboid.

  @argument playerName The name of the player to check.
  @argument cuboid A table defining the vertices of the cuboid using the key names P1, P2, P3, ..., P8. Must have at least P1, P2, P4, and P5.

  @notes The cuboid is defined from the bottom left corner to the top left corner, going clockwise

    This means the bottom rectangle is P1 - P4, while the top rectangle is P5-P8.

    Each point is a table with x, y, and z keys set to the x, y, and z values of the coordinate in the world.
]]
local function isPlayerWithin(playerName, cuboid)
  local player = debug.getPlayer(playerName)

  local vecPlayer = vector(player.getPosition())

  local vecP1 = vector(cuboid.P1.x, cuboid.P1.y, cuboid.P1.z)
  local vecP2 = vector(cuboid.P2.x, cuboid.P2.y, cuboid.P2.z)
  local vecP4 = vector(cuboid.P4.x, cuboid.P4.y, cuboid.P4.z)
  local vecP5 = vector(cuboid.P5.x, cuboid.P5.y, cuboid.P5.z)

  local uP1 = (vecP1 - vecP4)
  local uP2 = (vecP1 - vecP5)
  local vP1 = (vecP1 - vecP2)
  local vP2 = (vecP1 - vecP5)
  local wP1 = (vecP1 - vecP2)
  local wP2 = (vecP1 - vecP4)

  local u = uP1 * uP2
  local v = vP1 * vP2
  local w = wP1 * wP2

  local dotU = u:dot(vecPlayer)
  local dotV = v:dot(vecPlayer)
  local dotW = w:dot(vecPlayer)

  local tmpU = u:dot(u)
  local tmpV = v:dot(v)
  local tmpW = w:dot(w)

  if dotU > 0 and dotU < tmpU then
    if dotV > 0 and dotV < tmpV then
      if dotW > 0 and dotW < tmpW then
        return true
      end
    end
  end

  return false

end

local function playerHasItem(playerName, itemId, itemQuantity, slot, damage, nbt)

  local command = "/testfor @p[name=" .. playerName .. "] {Inventory:[{id:\"" .. itemId .. "\""

  if isnumber(itemQuantity) then
    command = command .. ",Count:" .. tostring(itemQuantity)
  end

  if isnumber(slot) then
    command = command .. ",Slot:" .. tostring(slot)
  end

  if isnumber(damage) then
    command = command .. ",Damage:" .. tostring(damage)
  end

  if isstring(nbt) then
    command = command .. ",tag:" .. nbt
  end

  command = command .. "}]}"

  return debug.runCommand(command) > 0

  --return debug.runCommand("/testfor @p[name=" .. playerName .. "] {Inventory:[{id:\"" .. itemId .. "\"}]}") > 0
end

local function givePlayerItem(playerName, itemId, quantity, meta, nbt)
  quantity = iif(isnumber(quantity), quantity, 1)
  meta = iif(isnumber(meta), meta, 0)

  local command = "/give " .. playerName .. " " .. itemId .. " " .. tostring(quantity) .. " " .. tostring(meta) .. " "

  if isstring(nbt) then
    command = command .. nbt
  end

  debug.runCommand(command)

end

local function teleportPlayer(playerName, x, y, z, yaw, pitch)

  local command = "/tp " .. playerName .. " " .. tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " "

  if isnumber(yaw) then
    command = command .. tostring(yaw) .. " "
    if isnumber(pitch) then
      command = command .. tostring(pitch)
    end
  end

  debug.runCommand(command)

end

local function setSingleBlock(x, y, z, blockId, meta, oldBlockHandling, nbt)

  if not isnumber(x) then
    error("x must be a number")
  end
  if not isnumber(y) then
    error("y must be a number")
  end
  if not isnumber(z) then
    error("z must be a number")
  end
  if not blockId then
    error("Must specify a block id")
  end

  meta = meta or 0
  oldBlockHandling = oldBlockHandling or "replace"

  local command = "/setblock " .. tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " " .. tostring(blockId) .. " "


  command = command .. tostring(meta) .. " "



  command = command .. oldBlockHandling .. " "

  if nbt then
    command = command .. nbt
  end

  debug.runCommand(command)

end

local function fillRegion(x1, y1, z1, x2, y2, z2, blockId, meta, oldBlockHandling, nbt)

  if not isnumber(x1) then
    error("x1 must be a number")
  end
  if not isnumber(y1) then
    error("x1 must be a number")
  end
  if not isnumber(z1) then
    error("x1 must be a number")
  end
  if not isnumber(x2) then
    error("x1 must be a number")
  end
  if not isnumber(y2) then
    error("x1 must be a number")
  end
  if not isnumber(z2) then
    error("x1 must be a number")
  end

  if not blockId then
    error("Must specify a block id")
  end

  meta = meta or 0
  oldBlockHandling = oldBlockHandling or "replace"

  local command = "/fill " .. tostring(x1) .. " " .. tostring(y1) .. " " .. tostring(z1) .. " " .. tostring(x2) .. " " .. tostring(y2) .. " " .. tostring(z2) .. " " .. tostring(blockId) .. " "

  command = command .. tostring(meta) .. " "


  command = command .. oldBlockHandling .. " "

  if nbt then
    command = command .. nbt
  end

  debug.runCommand(command)


end

return {
  isPlayerWithin = isPlayerWithin,
  playerHasItem = playerHasItem,
  givePlayerItem = givePlayerItem,
  teleportPlayer = teleportPlayer,
  setSingleBlock = setSingleBlock,
  fillRegion = fillRegion
}
