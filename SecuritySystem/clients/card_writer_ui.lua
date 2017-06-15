--[[

  card_writer_ui.lua - GUI for managing users for the OpenSecurity-Based door security system
  Author: Brisingr Aerowing
  Notes: Based on DustPuppy's security system

]]

local component = require("component")
local gui = require("gui")
local event = require("event")
local ser = require("serialization")
local util = require("securelib")
local fs = require("filesystem")
local writer = component.os_cardwriter

local myGui, cardStatusLabel, userList, cardNameLabel, cardNameText, userNameText, userLevelLabel, LevelUpButton, LevelDownButton
local cardBlockedYesButton, cardBlockedNoButton, userNewButton, userDeleteButton

local config = dofile("/etc/cardwriter.cfg")

local crypt_key = config.general.crypt_key
local network_port = config.general.network_port
local users_db_path = fs.concat(config.databases.database_path, config.databases.users_database_name)

local prgName = "Access System"
local version = "v0.1a"

local modem = component.modem

function buttonCallback(guiID, id)
  local result = gui.getYesNo("", "Do you really want to exit?", "")
  if result == true then
    gui.exit()
  end
end

function eventCallback(ev, id)
  if ev == "cardInsert" then
    gui.setText(myGui, cardStatusLabel, "   Card present")
  elseif ev == "cardRemove" then
    gui.setText(myGui, cardStatusLabel, "     No card   ")
  end
end

function userListCallback(guiID, listID, selectedID, selectedText)
  gui.setText(myGui, userNameText, userTable[selectedID].name)
  gui.setText(myGui, userLevelLabel, tostring(userTable[selectedID].level))
  if userTable[selectedID].blocked == true then
    gui.setEnable(myGui, cardBlockedYesButton, false)
    gui.setEnable(myGui, cardBlockedNoButton, true)
  else
    gui.setEnable(myGui, cardBlockedYesButton, true)
    gui.setEnable(myGui, cardBlockedNoButton, false)
  end
  gui.setEnable(myGui, LevelUpButton, true)
  gui.setEnable(myGui, LevelDownButton, true)
  gui.setEnable(myGui, userNameText, true)
end

function updateServer()
  local data = ser.serialize(userTable)
  local crypted = util.crypt(data, crypt_key)
  if not modem.isOpen(modemPort) then
    modem.open(modemPort)
  end
  modem.broadcast(modemPort, "updateuser", crypted)
end


function updateList()
  gui.clearList(myGui, userList)
  for key,value in pairs(userTable) do
    gui.insertList(myGui, userList, value.name)
  end
  util.saveTable(userTable, users_db_path)
  updateServer()
end

function blockUserCallback(guiID, id)
  local selected = gui.getSelected(myGui, userList)
  userTable[selected].blocked = true
  updateList()
  userListCallback(myGui, userList, selected)
end

function unblockUserCallback(guiID, id)
  local selected = gui.getSelected(myGui, userList)
  userTable[selected].blocked = false
  updateList()
  userListCallback(myGui, userList, selected)
end

function newUserCallback(guiID, id)
  local tmpTable = {["name"] = "new", ["blocked"] = false, ["level"] = 1, ["date"] = os.date()}
  table.insert(userTable, tmpTable)
  updateList()
end

function deleteUserCallback(guiID, id)
  local selected = gui.getSelected(myGui, userList)
  userTable[selected] = nil
  updateList()
  gui.setText(myGui, userNameText, "")
  gui.setText(myGui, userLevelLabel, "")
  gui.setEnable(myGui, cardBlockedYesButton, false)
  gui.setEnable(myGui, cardBlockedNoButton, false)
  gui.setEnable(myGui, LevelUpButton, false)
  gui.setEnable(myGui, LevelDownButton, false)
  gui.setEnable(myGui, userNameText, false)
end

function writeCardCallback(guiID, id)
  local cardName = gui.getText(myGui, cardNameText)
  if cardName == "" then
    gui.showMsg("Card name cannot be empty")
    return
  end
  local selected = gui.getSelected(myGui, userList)
  local data =  userTable[selected].date .. " " .. userTable[selected].name .. " " .. tostring(userTable[selected].level) .. " " .. tostring(userTable[selected].blocked)
  local crypted = util.crypt(data, cryptKey)
  writer.write(crypted, cardName, false)
end

function levelUpCallback(guiID, id)
  local selected = gui.getSelected(myGui, userList)
  if userTable[selected].level < math.maxinteger then
    userTable[selected].level = userTable[selected].level + 1
  end
  updateList()
  userListCallback(myGui, userList, selected)
end

function levelDownCallback(guiID, id)
  local selected = gui.getSelected(myGui, userList)
  if userTable[selected].level > 1 then
    userTable[selected].level = userTable[selected].level - 1
  end
  updateList()
  userListCallback(myGui, userList, selected)
end

function inputCallback(guiID, textID, text)
  local selected = gui.getSelected(myGui, userList)
  userTable[selected].name = text
  updateList()
  userListCallback(myGui, userList, selected)
end



-- main gui setup
myGui = gui.newGui(2, 2, 78, 23, true)
button = gui.newButton(myGui, "center", 21, "exit", buttonCallback)

-- frame with user list
gui.newFrame(myGui, 1, 1, 30, 18)
userList = gui.newList(myGui, 2, 2, 28, 16, {}, userListCallback)
userTable = util.loadTable(users_db_path)
if userTable == nil then
  userTable = {}
end
updateList()

-- user infos
gui.newLabel(myGui, 32, 6, "User name : ")
gui.newLabel(myGui, 32, 8, "Level     : ")
gui.newLabel(myGui, 32, 10, "Blocked   : [yes] / [no]")
userNameText = gui.newText(myGui, 44, 6, 16, "", inputCallback)
userLevelLabel = gui.newLabel(myGui, 44, 8, "")
LevelUpButton = gui.newButton(myGui, 48, 8, "+", levelUpCallback)
LevelDownButton = gui.newButton(myGui, 52, 8, "-", levelDownCallback)
cardBlockedYesButton = gui.newButton(myGui, 44, 10, "Yes", blockUserCallback)
cardBlockedNoButton = gui.newButton(myGui, 52, 10, "No", unblockUserCallback)
gui.setEnable(myGui, cardBlockedYesButton, false)
gui.setEnable(myGui, cardBlockedNoButton, false)
gui.setEnable(myGui, LevelUpButton, false)
gui.setEnable(myGui, LevelDownButton, false)
gui.setEnable(myGui, userNameText, false)

gui.newHLine(myGui, 32, 12, 43)

cardNameLabel = gui.newLabel(myGui, 32, 14, "Card Name:")
cardNameText = gui.newText(myGui, 43, 14, "SECURITY", cardNameCallback)

userNewButton = gui.newButton(myGui, 2, 21, "New", newUserCallback)
userDeleteButton = gui.newButton(myGui, 9, 21, "Delete", deleteUserCallback)

-- frame with status of the writer
gui.newFrame(myGui, 57, 1, 19, 3, "Writer status")
cardStatusLabel = gui.newLabel(myGui, 58, 2, "     No card   ")

--updateServerButton = gui.newButton(myGui, 47, 21, "update server", updateServerCallback)

cardWriteButton = gui.newButton(myGui, 64, 21, "Write Card", writeCardCallback)


gui.clearScreen()
gui.setTop(prgName .. " " .. version)

event.listen("cardInsert", eventCallback)
event.listen("cardRemove", eventCallback)

if not fs.isDirectory(config.databases.database_path) then
  fs.makeDirectory(config.databases.database_path)
end
while true do
  gui.runGui(myGui)
end