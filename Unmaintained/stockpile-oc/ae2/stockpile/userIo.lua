local M = {}
local MAX_OPTIONS = 13

local term = require("term")
local event = require("event")
local keys = require("keyboard").keys

function M.promptForNumber()

  local value = nil

  while value == nil do
    io.write("> ")
    value = tonumber(io.read())
    if value == nil then
      print("ERROR: Invalid number. Please try again")
    end
  end

  return value

end

function M.promptForNumberInRange(min, max)
  local value = nil
  while value == nil do
    local tValue = M.promptForNumber()

    if tValue < min then
      print("ERROR: please enter a number >= " .. min)
    elseif tValue > max then
      print("ERROR: please enter a number <= " .. max)
    else
      value = tValue
    end
  end

return value

end

function M.printOptions(options, banner)

  local page = 1
  local N = #options
  local maxPage = math.ceil(N / MAX_OPTIONS)
  local viewing = true

  while viewing do
    print(banner)

    if N > MAX_OPTIONS then

      term.clear()
      term.setCursor(1, 1)

      print(banner)
      print()

      print(string.format("Viewing %d items (%d/%d)", N, page, maxPage))
      print("------------------------------------")

    end

    local start = (((page - 1) * MAX_OPTIONS) + 1)
    for i = start, math.min(N, (start + MAX_OPTIONS - 1)), 1 do
      local option = options[i]
      if type(option) == "table" then
        option = option.name
      end
      print(string.format("%d. %s", i, option))
    end

    if N <= MAX_OPTIONS then
      break
    else
      print("------------------------------------")
      io.write("[j] previous, [k] next, [Enter] done")

      while true do
        local _, key, _, _ = event.pull("key_up")
        if key == keys.k then
          page = math.min(maxPage, page+1)
        elseif key == keys.j then
          page = math.max(1, page-1)
        elseif key == keys.enter then
          viewing = false
          break
        end
      end
    end

    if not viewing then
      print()
    end

  end

end

function M.chooseOption(options)
  M.printOptions(options)
  local option = M.promptForNumberInRange(1, #options)
  return options[option]
end

return M