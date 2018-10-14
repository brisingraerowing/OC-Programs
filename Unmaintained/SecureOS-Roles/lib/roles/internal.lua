--[[

  roles/internal.lua - Internal functions for the OpenSecurity User Roles implementation
  Author: Brisingr Aerowing

]]

local db_path = "/var/roles/db"
local roles_db_name = "roles.db"
local users_db_name = "users.db"
local roles_alias_db_name = "roles_alias.db"

local roles_db = nil
local users_db = nil
local alias_db = nil

local auth = require("auth")
local fs = require("filesystem")
local serialization = require("serialization")

-- Local functions

local function currentUserCanModifyRoles()

  initialize()

  local curUser = os.getenv("USER")

  -- If the user is an admin / superuser, allow editing roles
  local _, su = auth.validate(curUser, "*****")

  if su then
    return true
  end

  -- User is not an admin, check the users database.
  if users_db[curUser] then

    local tmp = users_db[curUser]

    return tmp["SYS_ROLE_MODIFY_USER_ROLES"]

  end

  return false

end

local maxIdGot = false

local function initialize()

  if roles_db == nil then
    loadRolesDb()
  end

  if users_db == nil then
    loadUsersDb()
  end

  addNewUsers()

  if alias_db == nil then
    loadAliasDb()
  end

  if not maxIdGot then

    for _, v in ipairs(roles_db) do
      if v.id and v.id > curMaxId then
        curMaxId = v.id
      end
    end
    maxIdGot = true
  end

end

-- Taken from auth.lua
local function split(str,sep)
  local array = {}
  local reg = string.format("([^%s]+)",sep)
  for mem in string.gmatch(str,reg) do
    table.insert(array, mem)
  end
  return array
end

-- Mostly taken from auth.lua
local function addNewUsers()

  local users = {}
  local u = io.open("/etc/passwd", "r")
  local raw = u:read("*a")

  if raw ~= nil then

    local temp = split(raw, "\n")

    for _,data in pairs(temp) do
      t = split(data, ":")
      table.insert(users, t[1])
    end

    for _, v in ipairs(users) do
      if not users_db[v] then
        users_db[v] = {roles={}}
      end
    end

    u:close()

  end

end

local function loadRolesDb()
  local db_file_path = fs.concat(db_path, roles_db_name)

  if not fs.exists(db_file_path) then
    roles_db = {}
    return
  end

  local file = io.open(db_file_path, "r")

  roles_db = serialization.unserialize(file:read("*a"))

  file:close()

end

local function saveRolesDb()

  local db_file_path = fs.concat(db_path, roles_db_name)

  local file = io.open(db_file_path, "w")

  file:write(serialization.serialize(roles_db))

  file:close()

end

local function loadUsersDb()

  local db_file_path = fs.concat(db_path, users_db_name)

  if not fs.exists(db_file_path) then
    users_db = {}
    return
  end

  local file = io.open(db_file_path, "r")

  users_db = serialization.unserialize(file:read("*a"))

  file:close()

end

local function saveUsersDb()

  local db_file_path = fs.concat(db_path, users_db_name)

  local file = io.open(db_file_path, "w")

  file:write(serialization.serialize(users_db))

  file:close()

end

local function loadAliasDb()
  local db_file_path = fs.concat(db_path, roles_alias_db_name)

  if not fs.exists(db_file_path) then
    alias_db = {}
    return
  end

  local file = io.open(db_file_path, "r")

  alias_db = serialization.unserialize(file:read("*a"))

  file:close()
end

local function saveAliasDb()
  local db_file_path = fs.concat(db_path, roles_alias_db_name)

  local file = io.open(db_file_path, "w")

  file:write(serialization.serialize(alias_db))

  file:close()
end

local curMaxId = 0

local function getNextId()

  curMaxId = curMaxId + 1

  return curMaxId

end

local function getRoleId(roleName)

  if alias_db[roleName] then
    roleName = alias_db[roleName]
  end

  return roles_db[roleName].id


end

local function tableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local function indexOf(t, o)

  local index = -1

  for k, v in ipairs(t) do
    if v == o then
      index = k
      break
    end
  end

  return index

end

return {

  db_path = db_path,
  roles_db_name = roles_db_name,
  users_db_name = users_db_name,
  roles_alias_db_name = roles_alias_db_name,

  roles_db = roles_db,
  users_db = users_db,
  alias_db = alias_db,

  initialize = initialize,
  currentUserCanModifyRoles = currentUserCanModifyRoles,
  addNewUsers = addNewUsers,
  loadRolesDb = loadRolesDb,
  saveRolesDb = saveRolesDb,
  loadUsersDb = loadUsersDb,
  saveUsersDb = saveUsersDb,
  loadAliasDb = loadAliasDb,
  saveAliasDb = saveAliasDb,
  getNextId = getNextId,
  getRoleId = getRoleId,
  tableLength = tableLength,
  indexOf = indexOf

}