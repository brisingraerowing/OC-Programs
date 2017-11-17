local tp = require("stockpile.tablePersistence")
local crc = require("stockpile.crc32lua")

local settings = nil

local SETTINGS_FILE = "/etc/stockpile_settings.cfg"

local M = {}

function M.load()

  local loaded = tp.load(SETTINGS_FILE)

  if loaded == nil then
    loaded = { stockedItems = {} }
  end

  settings = loaded

end

function M.save()
  tp.save(SETTINGS_FILE, settings)
end

function M.getStockedItems()
    if settings == nil then
      print("No settings found!")
    else
      return settings.stockedItems
    end
end

function M.removeStockedItem(item)
  settings.stockedItems[M.itemKey(item)] = nil
  M.save()
end

function M.setItemThreshold(item, threshold)
  local currentSettings = M.itemSettings(item)
  if currentSettings == nil then
    settings.stockedItems[M.itemKey(item)] = {
      item = item,
      threshold = threshold
    }
  else
    currentSettings.threshold = threshold
  end
  M.save()
end

function M.getItemThreshold(item)
  local itemCfg = itemSettings(item)
  if itemCfg ~= nil then
    return itemCfg.threshold
  else
    return nil
  end
end

function M.itemIsStocked(item)
  return itemSettings(item) ~= nil
end

function M.itemSettings(item)
  return M.getSettings().stockedItems[M.itemKey(item)]
end

function M.itemFromKey(key)
  local parts = split(key, "/")
  return {id = parts[1], dmg = parts[2]}
end

function M.itemKey(item)
  local key = item.name .. "/" .. item.damage

  if item.hasTag and item.tag then
    key = key .. "/" .. tostring(crc.crc32(item.tag))
  end

end