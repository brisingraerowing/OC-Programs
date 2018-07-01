local uio = require("stockpile.userIo")
local tp = require("stockpile.tablePersistence")
local sp = require("stockpile.settingsPersistence")
local component = require("component")

local CACHE_FILE = "/etc/stockpile_item_cache.dat"

local allItems = {}
local cache = {}
local aeInterface = component.me_controller

local M = {}

local function saveCache()
  tp.save(CACHE_FILE, cache)
end

local function loadCache()
  local loaded = tp.load(CACHE_FILE)

  if loaded == nil then
    loaded = { itemDetail = {} }
  end

  cache = loaded

end

function M.getItemDetail(item)

  local itemKey = sp.itemKey(item)

  if cache.itemDetail[itemKey] == nil then
    local itemDetail = aeInterface.getItemsInNetwork(item)[1]
    cache.itemDetail[itemKey] = { display_name = itemDetail.label }
  end

  return cache.itemDetail[itemKey]

end

function M.refreshItems()

  local tmpItems = aeInterface.getCraftables()

  for i, item in ipairs(tmpItems) do
    table.insert(allItems, item.getItemStack())
  end

  loadCache()

  for i, item in ipairs(allItems) do
    if item.itemDetails == nil then
      item.itemDetails = pcall(function() M.getItemDetail(item) end)
    end
  end

  saveCache()

end

function M.getAvailableItems()
  return allItems
end

local function stringMatches(s1, s2)
  if (s1 ~= s2) and (s1 == nil or s2 == nil) then
    return false
  else
    return string.find(string.lower(s1), string.lower(s2)) ~= nil
  end
end

local function isSameItem(i1, i2)

  return i1.name == i2.name and i1.damage == i2.damage

end

function M.findCraftableItem(itemToFind)

  for i, item in ipairs(allItems) do
    if isSameItem(item, itemToFind) then
      return item
    end
  end
  return nil
end

function M.findCraftableItemByName(itemName)
  local matchingItems = {}

  for i, item in ipairs(allItems) do

    local itemDetail = cache.itemDetail[sp.itemKey(item)]

    if itemDetail ~= nil and stringMatches(itemDetail.display_name, itemName) then
      table.insert(matchingItems, item)
    end

  end

  return matchingItems

end

function M.chooseCraftableItem()
  print("Type the name of an item")
  io.write("> ")
  local item = io.read()

  local results = findCraftableItemByName(item)

  if #results > 0 then
    local options = {}

    for i, item in ipairs(results) do
      local itemDetail = M.getItemDetail(item)

      local itemName = item.name

      if itemDetail ~= nil then
        itemName = itemDetail.display_name
      end

      table.insert(options, itemName)

    end

    uio.printOptions(options)

    print("Which did you mean? (0 to cancel)")
    local i = uio.promptForNumberInRange(0, #results)

    if i > 0 then
      return results[i]
    else
      return nil
    end
  else
    return nil
  end

end

return M