local sp = require("stockpile.settingsPersistence")
local cr = require("stockpile.craftingRequester")
local is = require("stockpile.itemSearcher")
local uio = require("stockpile.userIo")
local computer = require("computer")
local thread = require("thread")

local function handleUpdate()
  print("Updater not implemented... :-(")
end

local function handleSetThreshold()
  is.refreshItems()
  local item = is.chooseCraftableItem()

  if item ~= nil then
    local currentThreshold = sp.getItemThreshold(item)

    print("Enter the numer of items to keep stocked")
    if currentThreshold ~= nil then
      print("(Currently set to: ".. currentThreshold .. ")")
    end

    local threshold = uio.promptForNumberInRange(1, math.huge)

    sp.setItemThreshold(item, threshold)

    print("Successfully set threshold")

  else
    print("Couldn't find a matching item")
  end
end

function handleRemoveItem()

  is.refreshItems()

  local stockedItems = getStockedItems()

  viewStockedItems("Which item do you want to remove?")

  print("Item number to remove (0 to cancel)")
  local itemNum = uio.promptForNumberInRange(0, #stockedItems)

  if itemNum == 0 then
    print("Skipping removal")
  elseif itemNum ~= nil then
    sp.removeStockedItem(stockedItems[itemNum].stockedItem.item)
    print("Successfully removed stocked item")
  else
    print("Couldn't find a matching item")
  end

end

function viewStockedItems(banner)
  local printableItems = {}
  for i, item in ipairs(getStockedItems()) do
    table.insert(printableItems, item.itemDetailStr)
  end

  userIo.printOptions(printableItems, banner)
end

local function getStockedItems()
  local items = {}
  is.refreshItems()

  for key, stockedItem in pairs(sp.getStockedItems()) do
    local itemName = stockedItem.id
    local itemDetail = is.getItemDetail(stockedItem.item)

    if itemDetail ~= nil then
      itemName = itemDetail.display_name
    end

    local craftableItem = is.findCraftableItem(stockedItem.item)

    local amountInSystem = 0

    if craftableItem ~= nil then
      amountInSystem = craftableItem.size
    end

    table.insert(items, {
      itemDetailStr = string.format("%s (%d / %d)", itemName, amountInSystem, stockedItem.threshold),
      stockedItem = stockedItem
    })

  end

  table.sort(items, function(a, b) return a.itemDetailStr < b.itemDetailStr end)

  return items

end

local running = true

local function onInterupt(arg1, arg2)
  running = false
end

local function main()
  options = {
    {
      name = "Set threshold for an item",
      handler = handleSetThreshold
    },
    {
      name = "Remove item from stock monitoring",
      handler = handleRemoveItem
    },
    {
      name = "View stocked items",
      handler = function() viewStockedItems("") end
    },
    {
      name = "Update stockpile",
      handler = handleUpdate
    }
  }

  local t2 = thread.create(cr.monitorStockedItems)
  local t3 = thread.create(cr.monitorFinishedCraftingJobs)


  while running do
    sp.load()

    os.sleep(1)

    print()
    print()

    print("What do you want to do?")
    local selection = uio.chooseOption(options)
    selection.handler()

  end

  thread.waitForAll({t2, t3})

end

main()