--[[

  rolecfg.lua - Basic configuration program for the SecureOS User Roles implementation
  Author: Brisingr Aerowing

]]

local argparse = require("argparse")
local roles = require("roles")
local internal = require("roles.internal")

local parser = argparse():name("rolecfg"):description("Configuration program for user roles")
parser:command_target("command")

local cmd_add_role = parser:command("add-role"):description("Adds a new role")
cmd_add_role:argument("name"):description("The name of the new role")
cmd_add_role:argument("description"):description("The description of the new role")

local cmd_remove_role = parser:command("remove-role"):description("Removes an existing role")
cmd_remove_role:argument("name"):description("The name of the role to remove")

local cmd_update_description = parser:command("update-description"):description("Updates the description of a role")
cmd_update_description:argument("role"):description("The role to update the description of")
cmd_update_description:argument("new-description"):description("The new description for the role")

local cmd_role_exists = parser:command("role-exists"):description("Gets whether a role exists")
cmd_role_exists:argument("name"):description("The name of the role you want to check")

local cmd_role_info = parser:command("role-info"):description("Gets general information about a role")
cmd_role_info:argument("name"):description("The name of the role you want information on")

local cmd_rename_role = parser:command("rename-role"):description("Renames a role")
cmd_rename_role:argument("old-name"):description("The current name of the role")
cmd_rename_role:argument("new-name"):description("The new name for the role")
cmd_rename_role:flag("--no-alias"):description("Prevent adding an alias for backwards compatability")

local cmd_add_user_role = parser:command("add-user-role"):description("Adds a role to a user")
cmd_add_user_role:argument("user"):description("The name of the user to add a role to")
cmd_add_user_role:argument("role"):description("The role to add")

local cmd_remove_user_role = parser:command("remove-user-role"):description("Removes a role from a user")
cmd_remove_user_role:argument("user"):description("The name of the user to remove a role from")
cmd_remove_user_role:argument("role"):description("The role to remove")

local cmd_user_has_role = parser:command("user-has-role"):description("Gets whether the specified user has a role")
cmd_user_has_role:argument("user"):description("The name of the user to check for a role")
cmd_user_has_role:argument("role"):description("The role to check for")

local cmd_update_users = parser:command("update-users"):description("Updates the user database with new users")

local cmd_add_alias = parser:command("add-alias"):description("Adds an alias to a role.")
cmd_add_alias:argument("role"):description("The role to add an alias for")
cmd_add_alias:argument("alias"):description("The alias to add")

local cmd_remove_alias = parser:command("remove-alias"):description("Removes an alias")
cmd_remove_alias:argument("alias"):description("The alias to remove")

local cmd_is_alias = parser:command("is-alias"):description("Returns whether a role is actually an alias")
cmd_is_alias:argument("name"):description("The name of the role to check")

local cmd_exe_tbl = {

  ["add-role"] = function(args)

    local ok, msg = roles.addRole(args.name, args.description)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["remove-role"] = function(args)

    local ok, msg = roles.removeRole(args.name)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["update-description"] = function(args)

    local ok, msg = roles.updateRoleDescription(args.name, args["new-description"])

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["role-exists"] = function(args)

    if roles.roleExists(args.name) then
      print("Role " .. args.name .. " exists")
    else
      print("Role " .. args.name .. " does not exist")
    end

  end,

  ["role-info"] = function(args)

    local roleName = args.name

    local isAlias, actualName = roles.isAlias(roleName)
    local roleDesc = roles.getRoleDescription(roleName)
    local roleId = internal.getRoleId(roleName)

    print("Information about role " .. roleName)
    print("Is Alias: " .. tostring(isAlias))
    if isAlias then
      print("\tActual Role Name: " .. actualName)
    end
    print("Description: " .. roleDesc)
    print("ID: " .. tostring(roleId))

  end,

  ["rename-role"] = function(args)

    local oldName = args["old-name"]
    local newName = args["new-name"]
    local noAlias = args["no-alias"]

    local ok, msg = roles.renameRole(oleName, newName, noAlias)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["add-user-role"] = function(args)

    local ok, msg = roles.addUserRole(args.user, args.role)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["remove-user-role"] = function(args)

    local ok, msg = roles.removeUserRole(args.user, args.role)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["user-has-role"] = function(args)

    if roles.isUserInRole(args.user, args.role) then
      print("User " .. args.user .. " has role " .. args.role)
    else
      print("User " .. args.user .. " does not have role " .. args.role)
    end

  end,

  ["update-users"] = function(args)

    internal.addNewUsers()

  end,

  ["add-alias"] = function(args)

    local ok, msg = roles.addAlias(args.role, args.alias)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["remove-alias"] = function(args)

    local ok, msg = roles.removeAlias(args.alias)

    if not ok then
      print("ERROR: ", msg)
    end

  end,

  ["is-alias"] = function(args)

    local isAlias, actualName = roles.isAlias(args.name)

    if isAlias then
      print("Role " .. args.name .. " is an alias to " .. actualName)
    else
      print("Role " .. args.name .. " is not an alias")
    end

  end

}

local arg = {...}

local arguments = parser:parse(arg)

cmd_exe_tbl[arguments.command](arguments)