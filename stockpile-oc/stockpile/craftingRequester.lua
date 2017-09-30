local sp = require("stockpile.settingsPersistence")
local is = require("stockpile.itemSearcher")
local component = require("component")

local aeInterface = component.me_controller

local STOCK_PERCENTAGE = 0.05
local activeCraftingJobs = {}
local locked = false
local M = {}

function M.requestCrafting(item, number)
  aeInterface.getCraftables(item).request(number)
end

local function numItemsToStock(stockedItem, craftableItem)
  local numStocked = craftableItem.size
  local numWanted = stockedItem.threshold

  if numStocked >= numWanted then
    return 0
  else
    local targetCount = math.ceil(numWanted * (1+STOCK_PERCENTAGE))

    return targetCount - numStocked
  end

end

function M.monitorStockedItems()
  while true do
    sp.load()

    stockedItems = sp.getStockedItems()

    is.refreshItems()

    for key, stockedItem in pairs(stockedItems) do
      local craftableItem = is.findCraftableItem(stockedItem.item)

      if craftableItem ~= nil then
        local stockCount = numItemsToStock(stockedItem)

        if stockCount > 0 and activeCraftingJobs[key] == nil then
          --TODO: LOG
          -- log("Requesting " .. stockCount .. " " .. key)

          while locked do os.sleep(10) end
          locked = true
          activeCraftingJobs[key] = aeInterface.getCraftables(craftableItem).request(stockCount)
          locked = false
        end

      else

        --TODO: lOG
        -- log("ERROR: monitored item couldn't be found: " .. key)

      end

    end

    os.sleep(10)

  end
end

function M.monitorFinishedCraftingJobs()

  while true do

    while locked do os.sleep(10) end

    locked = true

    for key, job in pairs(activeCraftingJobs) do
      if job.isDone() then
        activeCraftingJobs[key] = nil
      end
    end

    locked = false

  end

end