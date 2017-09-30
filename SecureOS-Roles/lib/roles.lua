--[[

  roles.lua - User Roles implementation for SecureOS
  Author: Brisingr Aerowing

]]

local M = {}

local i = require("roles.internal")
local auth = require("auth")

-- Exported functions

function M.addRole(roleName, roleDescription)

  i.initialize()
  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to add new role: '" .. roleName .. "'.")
    return nil, "Permission denied."
  end

  if alias_db[roleName] then
    return nil, "Role '" .. roleName .. "' already registered as alias"
  end

  if i.roles_db[roleName] ~= nil then
    return nil,"Role '" .. roleName .. "' already registered!"
  end

  local role_id = i.getNextId()

  i.roles_db[roleName] = {id=role_id,description=roleDescription}

  i.saveRolesDb()

  return true

end

function M.removeRole(roleName)

  i.initialize()
  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to remove role: '" .. roleName .. "'.")
    return nil, "Permission denied."
  end

  if i.roles_db[roleName] == nil then
    return nil, "Role '" .. roleName .. "' is not registered."
  end

  i.roles_db[roleName] = nil

  i.saveRolesDb()

  return true

end

function M.updateRoleDescription(roleName, newDescription)

  i.initialize()
  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to update the description of role '" .. roleName .. "' to '" .. newDescription .. "'.")
    return nil, "Permission denied."
  end

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  if i.roles_db[roleName] == nil then
    return nil, "Role '" .. roleName .. "' is not registered."
  end

  i.roles_db[roleName].description = newDescription

  i.saveRolesDb()

  return true

end

function M.getRoleDescription(roleName)

  i.initialize()

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  local role = i.roles_db[roleName]

  if not role then
    return nil, "Role '" .. roleName .. "' not registered."
  end

  return role.description

end

function M.renameRole(oldName, newName, noAlias)

  i.initialize()

  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"),"Attempted to rename role '" .. oldName .. "' to '" .. newName .. "'.")
    return nil, "Permission denied."
  end

  local oldRole = i.roles_db[oldName]

  if oldRole == nil then
    return nil, "Role '" .. oldName .. "' not registered."
  end

  i.roles_db[newName] = {id=oldRole.id, description=oldRole.description}

  M.removeRole(oldName)

  if not noAlias then
    i.alias_db[oldName] = newName
  end

end

function M.roleExists(roleName)

  i.initialize()

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  return i.roles_db[roleName] ~= nil

end

function M.isUserInRole(userName, roleName)

  i.initialize()

  if i.users_db[userName] == nil then
    return nil, "User '" .. userName .. "' not in database.")
  end

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  local roleId = i.getRoleId(roleName)

  local userRoles = i.users_db[userName].roles

  local hasRole = false

  for _, v in ipairs(userRoles) do
    if roleId == v then
      hasRole = true
      break
    end
  end

  return hasRole

end

function M.addUserRole(userName, roleName)

  i.initialize()
  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to add role '" .. roleName .. "' to user '" .. userName .. "'.")
    return nil, "Permission denied."
  end

  if i.users_db[userName] == nil then
    return nil, "User '" .. userName .. "' not in database.")
  end

  if M.isUserInRole(userName, roleName) then
    return nil, "User '" .. userName .. "' already has role '" .. roleName .. "'."
  end

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  local roleId = i.getRoleId(roleName)

  local numUserRoles = i.tableLength(users_db[userName].roles)

  table.insert(i.users_db[userName].roles, numUserRoles + 1, roleId)

  i.saveUsersDb()

  return true

end

function M.removeUserRole(userName, roleName)

  i.initialize()
  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to remove role '" .. roleName .. "' from user '" .. userName .. "'.")
    return nil, "Permission denied."
  end

  if i.users_db[userName] == nil then
    return nil, "User '" .. userName .. "' not in database.")
  end

  if M.isUserInRole(userName, roleName) then
    return nil, "User '" .. userName .. "' does not have role '" .. roleName .. "'."
  end

  if i.alias_db[roleName] then
    roleName = i.alias_db[roleName]
  end

  local roleId = i.getRoleId(roleName)

  local index = i.indexOf(users_db[userName].roles, roleId)

  table.remove(i.users_db[userName].roles, index)

  i.saveUsersDb()

  return true

end

function M.addAlias(roleName, aliasName)

  i.initialize()

  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to add role alias '" .. aliasName .. "' to role '" .. roleName .. "'.")
    return nil, "Permission denied."
  end

  if i.alias_db[aliasName] then
    return nil, "Alias '" .. aliasName .. "' already registered"
  end

  i.alias_db[aliasName] = roleName

  i.saveAliasDb()

  return true

end

function M.removeAlias(aliasName)

  i.initialize()

  if not i.currentUserCanModifyRoles() then
    auth.userLog(os.getenv("USER"), "Attempted to remove role alias '" .. aliasName .. "'.")
    return nil, "Permission denied."
  end

  if not i.alias_db[aliasName] then
    return nil, "Alias '" .. aliasName .. "' not registered"
  end

  i.alias_db[aliasName] = nil

  i.saveAliasDb()

  return true

end

function M.isAlias(roleName)

  if i.alias_db[roleName] then
    return true, i.alias_db[roleName]
  end

  return false

end

return M